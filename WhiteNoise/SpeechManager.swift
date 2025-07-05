//
//  SpeechManager.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation

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
        
        let script = """
        tell application "System Events"
            set frontmostApp to name of first application process whose frontmost is true
            log "Активное приложение: " & frontmostApp
            keystroke "\(text)"
        end tell
        """
        
        print("[SpeechManager] Выполняем AppleScript: \(script)")
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("[SpeechManager] AppleScript завершен с кодом: \(process.terminationStatus)")
            print("[SpeechManager] AppleScript вывод: '\(output)'")
            
            if process.terminationStatus != 0 {
                print("[SpeechManager] ОШИБКА: AppleScript завершился с ошибкой")
            } else {
                print("[SpeechManager] Текст успешно вставлен")
            }
        }
        
        do {
            try task.run()
            print("[SpeechManager] AppleScript запущен")
        } catch {
            print("[SpeechManager] Ошибка запуска AppleScript: \(error)")
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
