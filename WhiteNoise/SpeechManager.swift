//
//  SpeechManager.swift
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
    private let swiftWhisperRecognizer = SwiftWhisperRecognizer()
    
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
        LogManager.shared.info("Вызван transcribeWithLocal для файла: \(fileURL.path)", component: .speechManager)
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            LogManager.shared.error("Файл не найден: \(fileURL.path)", component: .speechManager)
            completion(.failure(SpeechManagerError.fileNotFound))
            return
        }
        
        // Проверяем размер файла
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            LogManager.shared.info("Размер файла: \(fileSize) байт", component: .speechManager)
            
            if fileSize == 0 {
                LogManager.shared.warning("Файл пустой!", component: .speechManager)
                completion(.failure(SpeechManagerError.emptyFile))
                return
            }
        } catch {
            LogManager.shared.error("Ошибка получения атрибутов файла: \(error.localizedDescription)", component: .speechManager)
            completion(.failure(error))
            return
        }
        
        // Используем SwiftWhisper распознаватель
        swiftWhisperRecognizer.transcribeAudio(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let text):
                LogManager.shared.info("SwiftWhisper успешно вернул текст: '\(text)'", component: .speechManager)
                LogManager.shared.info("Вставляем текст в активное приложение...", component: .speechManager)
                self?.insertTextToFrontmostApp(text)
                completion(.success(text))
            case .failure(let error):
                LogManager.shared.error("Ошибка SwiftWhisper распознавания: \(error.localizedDescription)", component: .speechManager)
                completion(.failure(error))
            }
        }
    }
    
    private func insertTextToFrontmostApp(_ text: String) {
        LogManager.shared.info("Копируем текст в буфер обмена вместо вставки: \'\(text)\'", component: .speechManager)
        
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
                LogManager.shared.error("Ошибка отправки уведомления: \(error.localizedDescription)", component: .speechManager)
            } else {
                LogManager.shared.info("Уведомление о завершении распознавания отправлено", component: .speechManager)
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
        LogManager.shared.info("Попытка установить режим \(mode), но используется только локальный режим", component: .speechManager)
    }
    
    func getCurrentMode() -> RecognitionMode {
        return .local
    }
    
    func isLocalModelAvailable() -> Bool {
        let modelName = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        let sandboxPath = WhisperModel.modelsDirectory().appendingPathComponent(modelName)
        return FileManager.default.fileExists(atPath: sandboxPath.path)
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
