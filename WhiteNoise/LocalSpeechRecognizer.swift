//
//  LocalSpeechRecognizer.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AVFoundation

class LocalSpeechRecognizer {
    init() {
        // Больше не кэшируем путь к модели
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Конвертируем аудио в формат WAV для Whisper
        convertToWAV(from: fileURL) { [weak self] result in
            switch result {
            case .success(let wavURL):
                self?.performTranscription(wavURL: wavURL) { transcriptionResult in
                    completion(transcriptionResult)
                    // Удаляем временный WAV-файл только после завершения всех операций
                    try? FileManager.default.removeItem(at: wavURL)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func convertToWAV(from audioURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Проверяем, что файл существует и не пустой
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: audioURL.path) else {
            print("[LocalSpeechRecognizer] Исходный файл не существует: \(audioURL.path)")
            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
            return
        }
        do {
            let attrs = try fileManager.attributesOfItem(atPath: audioURL.path)
            if let fileSize = attrs[.size] as? UInt64, fileSize == 0 {
                print("[LocalSpeechRecognizer] Исходный файл пустой: \(audioURL.path)")
                completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                return
            } else {
                print("[LocalSpeechRecognizer] Исходный файл: \(audioURL.path), размер: \(attrs[.size] ?? 0) байт")
            }
        } catch {
            print("[LocalSpeechRecognizer] Ошибка получения атрибутов файла: \(error)")
            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
            return
        }

        // Если уже WAV, просто возвращаем путь
        if audioURL.pathExtension.lowercased() == "wav" {
            print("[LocalSpeechRecognizer] Файл уже WAV, пропускаем конвертацию")
            completion(.success(audioURL))
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let wavURL = tempDir.appendingPathComponent(UUID().uuidString + ".wav")
        print("[LocalSpeechRecognizer] Конвертация в WAV: \(wavURL.path)")

        let asset = AVURLAsset(url: audioURL)
        asset.loadTracks(withMediaType: .audio) { tracks, error in
            guard let track = tracks?.first else {
                print("[LocalSpeechRecognizer] Нет аудиотреков в файле: \(audioURL.path)")
                completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                return
            }

            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]

            do {
                let reader = try AVAssetReader(asset: asset)
                let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
                reader.add(readerOutput)

                let writer = try AVAssetWriter(outputURL: wavURL, fileType: .wav)
                let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
                writer.add(writerInput)

                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                let readerStarted = reader.startReading()
                print("[LocalSpeechRecognizer] reader.startReading() -> \(readerStarted), status: \(reader.status.rawValue)")
                if !readerStarted {
                    print("[LocalSpeechRecognizer] reader.error: \(String(describing: reader.error))")
                    completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                    return
                }

                let inputQueue = DispatchQueue(label: "audioInputQueue")
                writerInput.requestMediaDataWhenReady(on: inputQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if reader.status == .failed || reader.status == .completed {
                            print("[LocalSpeechRecognizer] reader.status: \(reader.status.rawValue), error: \(String(describing: reader.error))")
                            break
                        }
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(sampleBuffer)
                        } else {
                            writerInput.markAsFinished()
                            writer.finishWriting {
                                defer { try? FileManager.default.removeItem(at: wavURL) }
                                if writer.status == .completed {
                                    print("[LocalSpeechRecognizer] Конвертация завершена: \(wavURL.path)")
                                    completion(.success(wavURL))
                                } else {
                                    print("[LocalSpeechRecognizer] Ошибка завершения writer: \(String(describing: writer.error))")
                                    completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                                }
                            }
                            break
                        }
                    }
                }
            } catch {
                print("[LocalSpeechRecognizer] Ошибка конвертации: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func performTranscription(wavURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        print("[LocalSpeechRecognizer] Вызван performTranscription для файла: \(wavURL.path)")
        
        // Проверяем, что входной файл существует
        guard FileManager.default.fileExists(atPath: wavURL.path) else {
            print("[LocalSpeechRecognizer] ОШИБКА: Входной WAV файл не существует: \(wavURL.path)")
            completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
            return
        }
        
        // Используем Whisper.cpp через командную строку
        let process = Process()
        
        // Путь к бинарнику в бандле приложения
        guard let bundlePath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
            print("[LocalSpeechRecognizer] ОШИБКА: Бинарник whisper-cli не найден в бандле")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        process.executableURL = URL(fileURLWithPath: bundlePath)
        
        // Получаем выбранную модель
        let modelName = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/").appendingPathComponent(modelName)
        
        print("[LocalSpeechRecognizer] Проверяем путь к Whisper в бандле: \(bundlePath)")
        guard FileManager.default.fileExists(atPath: bundlePath) else {
            print("[LocalSpeechRecognizer] ОШИБКА: Whisper не найден по пути \(bundlePath)")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        print("[LocalSpeechRecognizer] Проверяем путь к модели: \(modelPath.path)")
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            print("[LocalSpeechRecognizer] ОШИБКА: Модель не найдена по пути \(modelPath.path)")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        let arguments = [
            "-m", modelPath.path,
            "-f", wavURL.path,
            "-l", "ru",
            "-otxt"
        ]
        process.arguments = arguments
        
        print("[LocalSpeechRecognizer] Запускаем Whisper с аргументами: \(arguments)")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.terminationHandler = { process in
            print("[LocalSpeechRecognizer] Whisper завершился с кодом: \(process.terminationStatus)")
        }
        
        do {
            print("[LocalSpeechRecognizer] Пытаемся запустить процесс...")
            try process.run()
            print("[LocalSpeechRecognizer] Процесс запущен, PID: \(process.processIdentifier)")
            
            print("[LocalSpeechRecognizer] Ждем завершения процесса...")
            process.waitUntilExit()
            print("[LocalSpeechRecognizer] Процесс завершен")
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("[LocalSpeechRecognizer] Whisper.cpp output: '\(output)'")
            
            if process.terminationStatus == 0 {
                // Новый способ: результат — это wavURL.path + ".txt"
                let outputFile = URL(fileURLWithPath: wavURL.path + ".txt")
                print("[LocalSpeechRecognizer] Ищем результат в файле: \(outputFile.path)")
                
                if FileManager.default.fileExists(atPath: outputFile.path) {
                    if let result = try? String(contentsOf: outputFile, encoding: .utf8) {
                        print("[LocalSpeechRecognizer] Результат распознавания: '\(result)' (длина: \(result.count))")
                        let punctuatedText = self.addPunctuation(to: result)
                        print("[LocalSpeechRecognizer] Текст с пунктуацией: '\(punctuatedText)'")
                        completion(.success(punctuatedText))
                    } else {
                        print("[LocalSpeechRecognizer] Не удалось прочитать результат из файла: \(outputFile.path)")
                        completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
                    }
                } else {
                    print("[LocalSpeechRecognizer] Файл с результатом не найден: \(outputFile.path)")
                    completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
                }
            } else {
                print("[LocalSpeechRecognizer] Whisper.cpp завершился с ошибкой: \(process.terminationStatus)")
                completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
            }
        } catch {
            print("[LocalSpeechRecognizer] Ошибка запуска Whisper.cpp: \(error)")
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
