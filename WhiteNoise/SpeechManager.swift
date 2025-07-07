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
    case openai = "openai"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .local:
            return "Локальная модель"
        case .openai:
            return "OpenAI API"
        case .auto:
            return "Автоматический выбор"
        }
    }
}

class SpeechManager {
    private let localRecognizer = LocalSpeechRecognizer()
    private let openAIRecognizer = SpeechRecognizer()
    
    private var currentMode: RecognitionMode {
        get {
            let savedMode = UserDefaults.standard.string(forKey: "RecognitionMode") ?? "auto"
            return RecognitionMode(rawValue: savedMode) ?? .auto
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "RecognitionMode")
        }
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        switch currentMode {
        case .local:
            transcribeWithLocal(fileURL: fileURL, completion: completion)
        case .openai:
            transcribeWithOpenAI(fileURL: fileURL, completion: completion)
        case .auto:
            transcribeWithAuto(fileURL: fileURL, completion: completion)
        }
    }
    
    private func transcribeWithLocal(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        print("[SpeechManager] Вызван transcribeWithLocal для файла: \(fileURL.path)")
        localRecognizer.transcribeAudio(fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    print("[SpeechManager] Локальная модель вернула текст: '\(text)'")
                    print("[SpeechManager] Вставляем текст в активное приложение...")
                    self?.insertTextToFrontmostApp(text)
                    completion(.success(text))
                case .failure(let error):
                    print("[SpeechManager] Ошибка локальной модели: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func insertTextToFrontmostApp(_ text: String) {
        print("[SpeechManager] Вызвана insertTextToFrontmostApp с текстом: '\(text)'")
        
        // Простой подход: копируем в буфер обмена и показываем уведомление
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("[SpeechManager] Текст скопирован в буфер обмена: '\(text)'")
        
        // Показываем уведомление с инструкцией
        let notification = NSUserNotification()
        notification.title = "WhiteNoise - Текст готов"
        notification.informativeText = "Распознанный текст скопирован в буфер обмена. Используйте Cmd+V для вставки в активное приложение."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
        
        // Пробуем несколько методов вставки
        DispatchQueue.global(qos: .background).async {
            // Метод 1: Прямая вставка
            self.trySimpleTextInsertion(text)
            
            // Метод 2: Через буфер обмена + Cmd+V (если первый не сработал)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.tryClipboardPaste()
            }
        }
    }
    
    private func trySimpleTextInsertion(_ text: String) {
        // Более прямой подход к вставке текста
        let script = """
        tell application "System Events"
            set frontmostApp to name of first application process whose frontmost is true
            log "Активное приложение: " & frontmostApp
            delay 0.1
            keystroke "\(text)"
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
            
            if process.terminationStatus == 0 {
                print("[SpeechManager] ✅ Текст успешно вставлен автоматически")
                // Показываем уведомление об успехе
                DispatchQueue.main.async {
                    let notification = NSUserNotification()
                    notification.title = "WhiteNoise - Успех"
                    notification.informativeText = "Текст автоматически вставлен в активное приложение"
                    notification.soundName = NSUserNotificationDefaultSoundName
                    NSUserNotificationCenter.default.deliver(notification)
                }
            } else {
                print("[SpeechManager] ℹ️ Автоматическая вставка не удалась, используйте Cmd+V")
                print("[SpeechManager] Ошибка: \(output)")
                
                // Показываем уведомление с инструкцией
                DispatchQueue.main.async {
                    let notification = NSUserNotification()
                    notification.title = "WhiteNoise - Используйте Cmd+V"
                    notification.informativeText = "Текст скопирован в буфер обмена. Нажмите Cmd+V для вставки."
                    notification.soundName = NSUserNotificationDefaultSoundName
                    NSUserNotificationCenter.default.deliver(notification)
                }
            }
        }
        
        do {
            try task.run()
            print("[SpeechManager] 🚀 Запущена попытка автоматической вставки...")
        } catch {
            print("[SpeechManager] Ошибка запуска AppleScript: \(error)")
        }
    }
    
    private func tryClipboardPaste() {
        // Альтернативный метод: копируем в буфер и вставляем через Cmd+V
        let script = """
        tell application "System Events"
            set frontmostApp to name of first application process whose frontmost is true
            log "Попытка вставки через Cmd+V в: " & frontmostApp
            delay 0.2
            key code 9 using {command down}
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
            
            if process.terminationStatus == 0 {
                print("[SpeechManager] ✅ Вставка через Cmd+V выполнена")
            } else {
                print("[SpeechManager] ℹ️ Вставка через Cmd+V не удалась: \(output)")
            }
        }
        
        do {
            try task.run()
        } catch {
            print("[SpeechManager] Ошибка запуска Cmd+V: \(error)")
        }
    }
    
    private func transcribeWithOpenAI(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        print("[SpeechManager] Вызван transcribeWithOpenAI для файла: \(fileURL.path)")
        openAIRecognizer.transcribeAudio(fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    print("[SpeechManager] OpenAI вернул текст: '\(text)'")
                    print("[SpeechManager] Вставляем текст в активное приложение...")
                    self?.insertTextToFrontmostApp(text)
                    completion(.success(text))
                case .failure(let error):
                    print("[SpeechManager] Ошибка OpenAI: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func transcribeWithAuto(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        print("[SpeechManager] Вызван transcribeWithAuto для файла: \(fileURL.path)")
        // Сначала пробуем OpenAI, если не получилось - используем локальную модель
        transcribeWithOpenAI(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let text):
                print("[SpeechManager] OpenAI успешно вернул текст: '\(text)'")
                print("[SpeechManager] Вставляем текст в активное приложение...")
                self?.insertTextToFrontmostApp(text)
                completion(.success(text))
            case .failure(let error):
                // Если OpenAI не сработал, пробуем локальную модель
                print("[SpeechManager] OpenAI не сработал: \(error.localizedDescription), пробуем локальную модель")
                self?.transcribeWithLocal(fileURL: fileURL, completion: completion)
            }
        }
    }
    
    func setRecognitionMode(_ mode: RecognitionMode) {
        currentMode = mode
    }
    
    func getCurrentMode() -> RecognitionMode {
        return currentMode
    }
    
    func isLocalModelAvailable() -> Bool {
        // Проверяем наличие Whisper в бандле приложения
        guard let whisperPath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
            return false
        }
        guard FileManager.default.fileExists(atPath: whisperPath) else {
            return false
        }
        
        // Проверяем наличие модели - используем реальную домашнюю директорию пользователя
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/ggml-tiny.bin")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    func isOpenAIAvailable() -> Bool {
        let apiKey = UserDefaults.standard.string(forKey: "OpenAI_API_Key") ?? ""
        return !apiKey.isEmpty
    }
    
    func getAvailableModes() -> [RecognitionMode] {
        var modes: [RecognitionMode] = []
        
        if isLocalModelAvailable() {
            modes.append(.local)
        }
        
        if isOpenAIAvailable() {
            modes.append(.openai)
        }
        
        if !modes.isEmpty {
            modes.append(.auto)
        }
        
        return modes
    }
} 
