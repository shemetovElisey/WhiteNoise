//
//  LocalSpeechRecognizer.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AVFoundation

class LocalSpeechRecognizer {
    private var whisperContext: OpaquePointer?
    private let modelPath: String
    
    init() {
        // Путь к модели Whisper (используется Homebrew версия)
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.modelPath = homeDir.appendingPathComponent("Documents/whisper-models/ggml-tiny.bin").path
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Конвертируем аудио в формат WAV для Whisper
        convertToWAV(from: fileURL) { [weak self] result in
            switch result {
            case .success(let wavURL):
                self?.performTranscription(wavURL: wavURL, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func convertToWAV(from audioURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let wavURL = documentsPath.appendingPathComponent("temp_audio.wav")

        // Используем AVURLAsset вместо AVAsset
        let asset = AVURLAsset(url: audioURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
            return
        }
        exportSession.outputURL = wavURL
        exportSession.outputFileType = .wav

        if #available(macOS 15.0, *) {
            // Новый способ: отслеживаем состояния через states(updateInterval:)
            let _ = exportSession.states(updateInterval: 0.1) { states in
                if let last = states.last {
                    switch last {
                    case .completed:
                        DispatchQueue.main.async {
                            completion(.success(wavURL))
                        }
                    case .failed, .cancelled:
                        DispatchQueue.main.async {
                            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                        }
                    default:
                        break
                    }
                }
            }
        } else {
            // Старый способ для совместимости
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    if exportSession.status == .completed {
                        completion(.success(wavURL))
                    } else {
                        completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                    }
                }
            }
        }
    }
    
    private func performTranscription(wavURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Используем Whisper.cpp через командную строку
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/whisper")
        
        // Путь к модели
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/ggml-tiny.bin")
        
        // Проверяем, установлен ли Whisper
        guard FileManager.default.fileExists(atPath: "/opt/homebrew/bin/whisper") else {
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        // Проверяем, есть ли модель
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        // Аргументы для Whisper
        process.arguments = [
            "-m", modelPath.path,
            "-f", wavURL.path,
            "-l", "ru",
            "-otxt"
        ]
        
        // Создаем pipe для вывода
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                // Читаем результат из файла
                let outputFile = wavURL.deletingPathExtension().appendingPathExtension("txt")
                if let result = try? String(contentsOf: outputFile, encoding: .utf8) {
                    let punctuatedText = self.addPunctuation(to: result)
                    completion(.success(punctuatedText))
                } else {
                    completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
                }
            } else {
                completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func addPunctuation(to text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Добавляем точку в конце, если нет знаков препинания
        if !result.isEmpty && !".!?".contains(result.last!) {
            result += "."
        }
        
        // Простые правила для улучшения пунктуации
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Заглавная буква в начале предложения
        if !result.isEmpty {
            result = String(result.prefix(1).uppercased()) + String(result.dropFirst())
        }
        
        return result
    }
    
    deinit {
        // Освобождаем ресурсы Whisper
        if let context = whisperContext {
            // whisper_free(context)
        }
    }
}

enum LocalSpeechRecognizerError: Error, LocalizedError {
    case modelNotFound
    case conversionFailed
    case transcriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Локальная модель не найдена"
        case .conversionFailed:
            return "Ошибка конвертации аудио"
        case .transcriptionFailed:
            return "Ошибка распознавания речи"
        }
    }
} 