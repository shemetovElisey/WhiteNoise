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
        requestMicrophonePermissionIfNeeded()
    }
    
    private func requestMicrophonePermissionIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if !granted {
                        self?.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
                    }
                }
            }
        case .denied, .restricted:
            microphonePermissionGranted = false
            showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
        @unknown default:
            microphonePermissionGranted = false
        }
    }
    
    func startRecording() {
        // Проверяем разрешение на микрофон
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                self.startActualRecording()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.startActualRecording()
                        } else {
                            self?.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
                        }
                    }
                }
            case .denied, .restricted:
                self.showError("Нет доступа к микрофону. Разрешите доступ в Системных настройках.")
            @unknown default:
                self.showError("Неизвестная ошибка доступа к микрофону.")
            }
        }
        
    }
    
    private func startActualRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_input.wav")
        print("[VoiceRecorder] Попытка начать запись: \(audioFilename.path)")
        
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
            print("[VoiceRecorder] AVAudioRecorder создан: \(audioRecorder != nil)")
            let started = audioRecorder?.record() ?? false
            print("[VoiceRecorder] .record() -> \(started)")
            if !started {
                print("[VoiceRecorder] AVAudioRecorder не смог начать запись. isRecording: \(audioRecorder?.isRecording ?? false)")
                showError("Ошибка: не удалось начать запись. Проверьте разрешения и настройки.")
                return
            }
            isRecording = true
            showRecordingIndicator()
        } catch {
            print("[VoiceRecorder] Ошибка создания AVAudioRecorder: \(error)")
            showError("Ошибка создания AVAudioRecorder: \(error.localizedDescription)")
            return
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
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
                print("[VoiceRecorder] Файл записан: \(audioFilename.path), размер: \(fileSize) байт")
                if fileSize == 0 {
                    print("[VoiceRecorder] ВНИМАНИЕ: файл пустой!")
                    showError("Ошибка: записанный файл пустой. Проверьте микрофон и разрешения.")
                }
            } catch {
                print("[VoiceRecorder] Ошибка получения атрибутов файла: \(error)")
            }
        } else {
            print("[VoiceRecorder] Файл не найден после записи: \(audioFilename.path)")
            showError("Ошибка: файл не найден после записи.")
        }
        // Начинаем обработку
        processRecording()
    }
    
    private func processRecording() {
        print("[VoiceRecorder] Вызван processRecording")
        isProcessing = true
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFile = documentsPath.appendingPathComponent("voice_input.wav")
        speechManager.transcribeAudio(fileURL: audioFile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let text):
                    print("[VoiceRecorder] Результат распознавания: \(text)")
                    self?.showNotification(title: "Voice Input", message: "Текст скопирован в буфер обмена: \(text.prefix(50))...")
                case .failure(let error):
                    print("[VoiceRecorder] Ошибка распознавания: \(error.localizedDescription)")
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
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    private func showRecordingIndicator() {
        self.showNotification(title: "Voice Input", message: "Запись началась... Говорите!")
    }
    
    private func hideRecordingIndicator() {
        self.showNotification(title: "Voice Input", message: "Запись завершена. Обрабатываем...")
    }
    
    private func showError(_ message: String) {
        self.showNotification(title: "Voice Input - Ошибка", message: message)
    }
}

extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            isRecording = false
            showError("Ошибка записи аудио")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
        if let error = error {
            showError("Ошибка кодирования: \(error.localizedDescription)")
        }
    }
} 
