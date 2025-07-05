//
//  VoiceRecorder.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AVFoundation
import AppKit

class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    
    private var audioRecorder: AVAudioRecorder?
    private let speechManager = SpeechManager()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        // На macOS AVAudioSession не используется, поэтому пропускаем эту настройку
        // AVAudioSession доступен только на iOS
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_input.m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            
            // Показываем индикатор записи
            showRecordingIndicator()
            
        } catch {
            print("Ошибка начала записи: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        // Скрываем индикатор записи
        hideRecordingIndicator()
        
        // Начинаем обработку
        processRecording()
    }
    
    private func processRecording() {
        isProcessing = true
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFile = documentsPath.appendingPathComponent("voice_input.m4a")
        
        speechManager.transcribeAudio(fileURL: audioFile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                switch result {
                case .success(let text):
                    self?.insertText(text)
                case .failure(let error):
                    self?.showError("Ошибка распознавания: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func insertText(_ text: String) {
        // Экранируем специальные символы для AppleScript
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\\", with: "\\\\")
        
        // Создаем AppleScript для вставки текста
        let script = """
        tell application "System Events"
            keystroke "\(escapedText)"
        end tell
        """
        
        if let scriptObject = NSAppleScript(source: script) {
            var error: NSDictionary?
            scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                showError("Ошибка вставки текста: \(error)")
            } else {
                // Показываем уведомление об успешной вставке
                let notification = NSUserNotification()
                notification.title = "Voice Input"
                notification.informativeText = "Текст вставлен: \(text.prefix(50))..."
                NSUserNotificationCenter.default.deliver(notification)
            }
        }
    }
    
    private func showRecordingIndicator() {
        // Показываем уведомление о начале записи
        let notification = NSUserNotification()
        notification.title = "Voice Input"
        notification.informativeText = "Запись началась... Говорите!"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func hideRecordingIndicator() {
        // Показываем уведомление о завершении записи
        let notification = NSUserNotification()
        notification.title = "Voice Input"
        notification.informativeText = "Запись завершена. Обрабатываем..."
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func showError(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "Voice Input - Ошибка"
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
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