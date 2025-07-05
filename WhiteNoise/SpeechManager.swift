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
        localRecognizer.transcribeAudio(fileURL: fileURL) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func transcribeWithOpenAI(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        openAIRecognizer.transcribeAudio(fileURL: fileURL) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func transcribeWithAuto(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Сначала пробуем OpenAI, если не получилось - используем локальную модель
        transcribeWithOpenAI(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let text):
                completion(.success(text))
            case .failure(let error):
                // Если OpenAI не сработал, пробуем локальную модель
                print("OpenAI не сработал: \(error.localizedDescription), пробуем локальную модель")
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
        // Проверяем наличие Whisper в системе
        let whisperPath = "/opt/homebrew/bin/whisper"
        guard FileManager.default.fileExists(atPath: whisperPath) else {
            return false
        }
        
        // Проверяем наличие модели
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
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