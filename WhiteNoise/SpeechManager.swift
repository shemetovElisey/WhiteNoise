//
//  SpeechManager.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AppKit
import UserNotifications

enum RecognitionMode: String, CaseIterable {
    case local = "local"
    
    var displayName: String {
        switch self {
        case .local:
            return "Локальная модель"
        }
    }
}

class SpeechManager {
    private let localRecognizer = LocalSpeechRecognizer()
    
    private var currentMode: RecognitionMode {
        get {
            return .local // Всегда используем локальную модель
        }
        set {
            // Игнорируем, так как у нас только один режим
        }
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        transcribeWithLocal(fileURL: fileURL, completion: completion)
    }
    
    private func transcribeWithLocal(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        LogManager.shared.info("Вызван transcribeWithLocal для файла: \(fileURL.path)", component: "SpeechManager")
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            LogManager.shared.error("Файл не найден: \(fileURL.path)", component: "SpeechManager")
            completion(.failure(SpeechManagerError.fileNotFound))
            return
        }
        
        // Проверяем размер файла
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            LogManager.shared.info("Размер файла: \(fileSize) байт", component: "SpeechManager")
            
            if fileSize == 0 {
                LogManager.shared.warning("Файл пустой!", component: "SpeechManager")
                completion(.failure(SpeechManagerError.emptyFile))
                return
            }
        } catch {
            LogManager.shared.error("Ошибка получения атрибутов файла: \(error.localizedDescription)", component: "SpeechManager")
            completion(.failure(error))
            return
        }
        
        // Используем локальный распознаватель
        localRecognizer.transcribeAudio(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let text):
                LogManager.shared.info("Локальная модель успешно вернула текст: '\(text)'", component: "SpeechManager")
                LogManager.shared.info("Вставляем текст в активное приложение...", component: "SpeechManager")
                self?.insertTextToFrontmostApp(text)
                completion(.success(text))
            case .failure(let error):
                LogManager.shared.error("Ошибка локального распознавания: \(error.localizedDescription)", component: "SpeechManager")
                completion(.failure(error))
            }
        }
    }
    
    private func insertTextToFrontmostApp(_ text: String) {
        LogManager.shared.info("Копируем текст в буфер обмена вместо вставки: \'\(text)\'", component: "SpeechManager")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Показываем красивое уведомление о готовности текста
        self.showRecognitionCompleteNotification(text: text)
    }
    
    private func showRecognitionCompleteNotification(text: String) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Распознано!"
        content.body = "Текст скопирован в буфер обмена"
        content.sound = .default
        
        // Добавляем действия для быстрого доступа
        content.userInfo = ["text": text]
        
        let request = UNNotificationRequest(identifier: "recognition_complete_\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LogManager.shared.error("Ошибка отправки уведомления: \(error.localizedDescription)", component: "SpeechManager")
            } else {
                LogManager.shared.info("Уведомление о завершении распознавания отправлено", component: "SpeechManager")
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
    
    func setRecognitionMode(_ mode: RecognitionMode) {
        // Игнорируем, так как у нас только один режим
        LogManager.shared.info("Попытка установить режим \(mode), но используется только локальный режим", component: "SpeechManager")
    }
    
    func getCurrentMode() -> RecognitionMode {
        return .local
    }
    
    func isLocalModelAvailable() -> Bool {
        // Проверяем наличие Whisper в бандле приложения
        guard let whisperPath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
            return false
        }
        guard FileManager.default.fileExists(atPath: whisperPath) else {
            return false
        }
        
        // Проверяем наличие выбранной модели
        let modelName = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/").appendingPathComponent(modelName)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    func getAvailableModes() -> [RecognitionMode] {
        // Возвращаем только локальный режим, если модель доступна
        if isLocalModelAvailable() {
            return [.local]
        }
        return []
    }
}

// Ошибки для SpeechManager
enum SpeechManagerError: Error, LocalizedError {
    case fileNotFound
    case emptyFile
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Аудиофайл не найден"
        case .emptyFile:
            return "Аудиофайл пустой"
        }
    }
} 
