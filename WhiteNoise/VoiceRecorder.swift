//
//  VoiceRecorder.swift
//  WhiteNoise
//
//  Copyright (c) 2025 Elisey Shemetov. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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
        LogManager.shared.info("VoiceRecorder инициализирован", component: .voiceRecorder)
        requestMicrophonePermissionIfNeeded()
    }
    
    private func requestMicrophonePermissionIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
            LogManager.shared.info("Разрешение на микрофон уже предоставлено", component: .voiceRecorder)
        case .notDetermined:
            LogManager.shared.info("Запрашиваем разрешение на микрофон", component: .voiceRecorder)
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if granted {
                        LogManager.shared.info("Разрешение на микрофон предоставлено", component: .voiceRecorder)
                    } else {
                        LogManager.shared.warning("Разрешение на микрофон не предоставлено", component: .voiceRecorder)
                        self?.showError("permission_denied".localized)
                    }
                }
            }
        case .denied, .restricted:
            microphonePermissionGranted = false
            LogManager.shared.warning("permission_denied".localized, component: .voiceRecorder)
            showError("permission_denied".localized)
        @unknown default:
            microphonePermissionGranted = false
            LogManager.shared.error("Неизвестный статус разрешения микрофона", component: .voiceRecorder)
        }
    }
    
    func startRecording() {
        LogManager.shared.info("Запрос на начало записи", component: .voiceRecorder)
        
        // Проверяем разрешение на микрофон
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                LogManager.shared.info("Разрешение на микрофон подтверждено, начинаем запись", component: .voiceRecorder)
                self.startActualRecording()
            case .notDetermined:
                LogManager.shared.info("Запрашиваем разрешение на микрофон", component: .voiceRecorder)
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            LogManager.shared.info("Разрешение получено, начинаем запись", component: .voiceRecorder)
                            self?.startActualRecording()
                        } else {
                            LogManager.shared.warning("Разрешение на микрофон не получено", component: .voiceRecorder)
                            self?.showError("permission_denied".localized)
                        }
                    }
                }
            case .denied, .restricted:
                LogManager.shared.warning("permission_denied".localized, component: .voiceRecorder)
                self.showError("permission_denied".localized)
            @unknown default:
                LogManager.shared.error("Неизвестная ошибка доступа к микрофону", component: .voiceRecorder)
                self.showError("Неизвестная ошибка доступа к микрофону.")
            }
        }
    }
    
    private func startActualRecording() {
        guard !isRecording else { 
            LogManager.shared.warning("recording_in_progress".localized, component: .voiceRecorder)
            return 
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_input.wav")
        LogManager.shared.info("Попытка начать запись: \(audioFilename.path)", component: .voiceRecorder)
        
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
            LogManager.shared.debug("AVAudioRecorder создан: \(audioRecorder != nil)", component: .voiceRecorder)
            let started = audioRecorder?.record() ?? false
            LogManager.shared.debug("AVAudioRecorder.record() -> \(started)", component: .voiceRecorder)
            if !started {
                LogManager.shared.error("recording_error".localized(with: "AVAudioRecorder не смог начать запись"), component: .voiceRecorder)
                showError("recording_error".localized(with: "не удалось начать запись"))
                return
            }
            isRecording = true
            LogManager.shared.info("recording_started".localized, component: .voiceRecorder)
            showRecordingIndicator()
        } catch {
            LogManager.shared.error("recording_error".localized(with: error.localizedDescription), component: .voiceRecorder)
            showError("recording_error".localized(with: error.localizedDescription))
            return
        }
    }
    
    func stopRecording() {
        guard isRecording else { 
            LogManager.shared.warning("no_recording_in_progress".localized, component: .voiceRecorder)
            return 
        }
        
        LogManager.shared.info("Останавливаем запись", component: .voiceRecorder)
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
                LogManager.shared.info("Файл записан: \(audioFilename.path), размер: \(fileSize) байт", component: .voiceRecorder)
                if fileSize == 0 {
                    LogManager.shared.warning("ВНИМАНИЕ: файл пустой!", component: .voiceRecorder)
                    showError("recording_error".localized(with: "записанный файл пустой"))
                }
            } catch {
                LogManager.shared.error("Ошибка получения атрибутов файла: \(error.localizedDescription)", component: .voiceRecorder)
            }
        } else {
            LogManager.shared.error("Файл не найден после записи: \(audioFilename.path)", component: .voiceRecorder)
            showError("recording_error".localized(with: "файл не найден после записи"))
        }
        
        // Начинаем обработку
        processRecording()
    }
    
    private func processRecording() {
        LogManager.shared.info("Вызван processRecording", component: .voiceRecorder)
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
                    LogManager.shared.info("Распознавание завершено успешно", component: .voiceRecorder)
                    self?.copyToClipboard(text)
                    self?.showSuccessNotification(text)
                case .failure(let error):
                    LogManager.shared.error("Ошибка распознавания: \(error.localizedDescription)", component: .voiceRecorder)
                    self?.showError("Ошибка распознавания: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        LogManager.shared.info("text_copied_to_clipboard".localized, component: .voiceRecorder)
    }
    
    private func showRecordingIndicator() {
        // Показываем уведомление о начале записи
        let content = UNMutableNotificationContent()
        content.title = "Voice Input"
        content.body = "Запись началась..."
        content.sound = nil
        
        let request = UNNotificationRequest(identifier: "recording_started", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func hideRecordingIndicator() {
        // Удаляем уведомление о записи
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["recording_started"])
    }
    
    private func showProcessingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Voice Input"
        content.body = "Обработка аудио..."
        content.sound = nil
        
        let request = UNNotificationRequest(identifier: "processing", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showSuccessNotification(_ text: String) {
        // Удаляем уведомление о обработке
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["processing"])
        
        let content = UNMutableNotificationContent()
        content.title = "Voice Input"
        content.body = "Текст скопирован в буфер обмена"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "success", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showError(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Voice Input - Ошибка"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "error", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}