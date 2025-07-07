//
//  SpeechManager.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AppKit

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
        print("[SpeechManager] Вызван transcribeWithLocal для файла: \(fileURL.path)")
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[SpeechManager] Файл не найден: \(fileURL.path)")
            completion(.failure(SpeechManagerError.fileNotFound))
            return
        }
        
        // Проверяем размер файла
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            print("[SpeechManager] Размер файла: \(fileSize) байт")
            
            if fileSize == 0 {
                print("[SpeechManager] Файл пустой!")
                completion(.failure(SpeechManagerError.emptyFile))
                return
            }
        } catch {
            print("[SpeechManager] Ошибка получения атрибутов файла: \(error)")
            completion(.failure(error))
            return
        }
        
        // Используем локальный распознаватель
        localRecognizer.transcribeAudio(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let text):
                print("[SpeechManager] Локальная модель успешно вернула текст: '\(text)'")
                print("[SpeechManager] Вставляем текст в активное приложение...")
                self?.insertTextToFrontmostApp(text)
                completion(.success(text))
            case .failure(let error):
                print("[SpeechManager] Ошибка локального распознавания: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func insertTextToFrontmostApp(_ text: String) {
        print("[SpeechManager] Вставляем текст: '\(text)'")
        
        // Получаем активное приложение
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("[SpeechManager] Не удалось получить активное приложение")
            return
        }
        
        print("[SpeechManager] Активное приложение: \(frontmostApp.localizedName ?? "Unknown")")
        
        // Создаем AppleScript для вставки текста
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "System Events"
            keystroke "\(escapedText)"
        end tell
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    print("[SpeechManager] Текст успешно вставлен")
                    self.showNotification(title: "Voice Input", message: "Текст вставлен: \(text.prefix(50))...")
                } else {
                    print("[SpeechManager] Ошибка вставки текста: \(output)")
                    self.showNotification(title: "Voice Input - Ошибка", message: "Не удалось вставить текст. Используйте Cmd+V вручную.")
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            print("[SpeechManager] Ошибка запуска AppleScript: \(error)")
            showNotification(title: "Voice Input - Ошибка", message: "Ошибка вставки: \(error.localizedDescription)")
        }
    }
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func setRecognitionMode(_ mode: RecognitionMode) {
        // Игнорируем, так как у нас только один режим
        print("[SpeechManager] Попытка установить режим \(mode), но используется только локальный режим")
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
