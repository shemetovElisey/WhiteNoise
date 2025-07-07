//
//  VoiceRecorder.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AVFoundation
import AppKit
import UserNotifications

// Добавляем имя уведомления
extension Notification.Name {
    static let recordingStateChanged = Notification.Name("recordingStateChanged")
}

class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false {
        didSet {
            // Уведомляем AppDelegate об изменении состояния
            NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
        }
    }
    @Published var isProcessing = false
    
    private var audioRecorder: AVAudioRecorder?
    private let speechManager = SpeechManager()
    private var microphonePermissionGranted: Bool = false
    
    override init() {
        super.init()
        LogManager.shared.info("VoiceRecorder инициализирован", component: "VoiceRecorder")
        requestMicrophonePermissionIfNeeded()
    }
    
    private func requestMicrophonePermissionIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
            LogManager.shared.info("Разрешение на микрофон уже предоставлено", component: "VoiceRecorder")
        case .notDetermined:
            LogManager.shared.info("Запрашиваем разрешение на микрофон", component: "VoiceRecorder")
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if granted {
                        LogManager.shared.info("Разрешение на микрофон предоставлено", component: "VoiceRecorder")
                    } else {
                        LogManager.shared.warning("Разрешение на микрофон не предоставлено", component: "VoiceRecorder")
                        self?.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
                    }
                }
            }
        case .denied, .restricted:
            microphonePermissionGranted = false
            LogManager.shared.warning("Доступ к микрофону запрещен", component: "VoiceRecorder")
            showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
        @unknown default:
            microphonePermissionGranted = false
            LogManager.shared.error("Неизвестный статус разрешения микрофона", component: "VoiceRecorder")
        }
    }
    
    func startRecording() {
        LogManager.shared.info("Запрос на начало записи", component: "VoiceRecorder")
        
        // Проверяем разрешение на микрофон
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                LogManager.shared.info("Разрешение на микрофон подтверждено, начинаем запись", component: "VoiceRecorder")
                self.startActualRecording()
            case .notDetermined:
                LogManager.shared.info("Запрашиваем разрешение на микрофон", component: "VoiceRecorder")
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            LogManager.shared.info("Разрешение получено, начинаем запись", component: "VoiceRecorder")
                            self?.startActualRecording()
                        } else {
                            LogManager.shared.warning("Разрешение на микрофон не получено", component: "VoiceRecorder")
                            self?.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
                        }
                    }
                }
            case .denied, .restricted:
                LogManager.shared.warning("Доступ к микрофону запрещен", component: "VoiceRecorder")
                self.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
            @unknown default:
                LogManager.shared.error("Неизвестная ошибка доступа к микрофону", component: "VoiceRecorder")
                self.showError("Неизвестная ошибка доступа к микрофону.")
            }
        }
    }
    
    private func startActualRecording() {
        guard !isRecording else { 
            LogManager.shared.warning("Попытка начать запись, когда уже записывается", component: "VoiceRecorder")
            return 
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_input.wav")
        LogManager.shared.info("Попытка начать запись: \(audioFilename.path)", component: "VoiceRecorder")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            LogManager.shared.debug("AVAudioRecorder создан: \(audioRecorder != nil)", component: "VoiceRecorder")
            let started = audioRecorder?.record() ?? false
            LogManager.shared.debug("AVAudioRecorder.record() -> \(started)", component: "VoiceRecorder")
            if !started {
                LogManager.shared.error("AVAudioRecorder не смог начать запись. isRecording: \(audioRecorder?.isRecording ?? false)", component: "VoiceRecorder")
                showError("Ошибка: не удалось начать запись. Проверьте разрешения и настройки.")
                return
            }
            isRecording = true
            LogManager.shared.info("Запись начата успешно", component: "VoiceRecorder")
            showRecordingIndicator()
        } catch {
            LogManager.shared.error("Ошибка создания AVAudioRecorder: \(error.localizedDescription)", component: "VoiceRecorder")
            showError("Ошибка создания AVAudioRecorder: \(error.localizedDescription)")
            return
        }
    }
    
    func stopRecording() {
        guard isRecording else { 
            LogManager.shared.warning("Попытка остановить запись, когда не записывается", component: "VoiceRecorder")
            return 
        }
        
        LogManager.shared.info("Останавливаем запись", component: "VoiceRecorder")
        audioRecorder?.stop()
        isRecording = false
        hideRecordingIndicator()
        
        // Проверяем файл после записи
        let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("voice_input.wav")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: audioFilename.path) {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: audioFilename.path)
                let fileSize = attrs[.size] as? UInt64 ?? 0
                LogManager.shared.info("Файл записан: \(audioFilename.path), размер: \(fileSize) байт", component: "VoiceRecorder")
                if fileSize == 0 {
                    LogManager.shared.warning("ВНИМАНИЕ: файл пустой!", component: "VoiceRecorder")
                    showError("Ошибка: записанный файл пустой. Проверьте микрофон и разрешения.")
                }
            } catch {
                LogManager.shared.error("Ошибка получения атрибутов файла: \(error.localizedDescription)", component: "VoiceRecorder")
            }
        } else {
            LogManager.shared.error("Файл не найден после записи: \(audioFilename.path)", component: "VoiceRecorder")
            showError("Ошибка: файл не найден после записи.")
        }
        
        // Начинаем обработку
        processRecording()
    }
    
    private func processRecording() {
        LogManager.shared.info("Вызван processRecording", component: "VoiceRecorder")
        isProcessing = true
        
        // Показываем уведомление о начале обработки
        showProcessingNotification()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFile = documentsPath.appendingPathComponent("voice_input.wav")
        speechManager.transcribeAudio(fileURL: audioFile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let text):
                    LogManager.shared.info("Результат распознавания: \(text)", component: "VoiceRecorder")
                    // Уведомление о завершении будет показано в SpeechManager
                case .failure(let error):
                    LogManager.shared.error("Ошибка распознавания: \(error.localizedDescription)", component: "VoiceRecorder")
                    self?.showError("Ошибка распознавания: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Добавляем информацию о приложении
        content.userInfo = ["app": "WhiteNoise"]
        
        let request = UNNotificationRequest(identifier: "voice_recorder_\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LogManager.shared.error("Ошибка отправки уведомления: \(error.localizedDescription)", component: "VoiceRecorder")
            }
        }
    }
    
    private func showRecordingIndicator() {
        // Убираем уведомление о начале записи - пользователь сам знает, что записывает
    }
    
    private func hideRecordingIndicator() {
        // Убираем уведомление о завершении записи
    }
    
    private func showProcessingNotification() {
        self.showNotification(title: "🔄 Распознавание речи", message: "Обрабатываем ваш голос...")
    }
    
    private func showError(_ message: String) {
        self.showNotification(title: "Voice Input - Ошибка", message: message)
    }
}

extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            LogManager.shared.error("Ошибка записи аудио", component: "VoiceRecorder")
            isRecording = false
            showError("Ошибка записи аудио")
        } else {
            LogManager.shared.info("Запись аудио завершена успешно", component: "VoiceRecorder")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
        if let error = error {
            LogManager.shared.error("Ошибка кодирования: \(error.localizedDescription)", component: "VoiceRecorder")
            showError("Ошибка кодирования: \(error.localizedDescription)")
        }
    }
} 
