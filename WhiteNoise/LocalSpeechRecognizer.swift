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
        LogManager.shared.info("LocalSpeechRecognizer инициализирован", component: "LocalSpeechRecognizer")
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        LogManager.shared.info("Начинаем транскрипцию файла: \(fileURL.path)", component: "LocalSpeechRecognizer")
        
        // Конвертируем аудио в формат WAV для Whisper
        convertToWAV(from: fileURL) { [weak self] result in
            switch result {
            case .success(let wavURL):
                LogManager.shared.info("Конвертация в WAV успешна, начинаем транскрипцию", component: "LocalSpeechRecognizer")
                self?.performTranscription(wavURL: wavURL) { transcriptionResult in
                    completion(transcriptionResult)
                    // Удаляем временный WAV-файл только после завершения всех операций
                    try? FileManager.default.removeItem(at: wavURL)
                }
            case .failure(let error):
                LogManager.shared.error("Ошибка конвертации в WAV: \(error.localizedDescription)", component: "LocalSpeechRecognizer")
                completion(.failure(error))
            }
        }
    }
    
    private func convertToWAV(from audioURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Проверяем, что файл существует и не пустой
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: audioURL.path) else {
            LogManager.shared.error("Исходный файл не существует: \(audioURL.path)", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
            return
        }
        do {
            let attrs = try fileManager.attributesOfItem(atPath: audioURL.path)
            if let fileSize = attrs[.size] as? UInt64, fileSize == 0 {
                LogManager.shared.warning("Исходный файл пустой: \(audioURL.path)", component: "LocalSpeechRecognizer")
                completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                return
            } else {
                LogManager.shared.info("Исходный файл: \(audioURL.path), размер: \(attrs[.size] ?? 0) байт", component: "LocalSpeechRecognizer")
            }
        } catch {
            LogManager.shared.error("Ошибка получения атрибутов файла: \(error.localizedDescription)", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.conversionFailed))
            return
        }

        // Если уже WAV, просто возвращаем путь
        if audioURL.pathExtension.lowercased() == "wav" {
            LogManager.shared.info("Файл уже WAV, пропускаем конвертацию", component: "LocalSpeechRecognizer")
            completion(.success(audioURL))
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let wavURL = tempDir.appendingPathComponent(UUID().uuidString + ".wav")
        LogManager.shared.info("Конвертация в WAV: \(wavURL.path)", component: "LocalSpeechRecognizer")

        let asset = AVURLAsset(url: audioURL)
        asset.loadTracks(withMediaType: .audio) { tracks, error in
            guard let track = tracks?.first else {
                LogManager.shared.error("Нет аудиотреков в файле: \(audioURL.path)", component: "LocalSpeechRecognizer")
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
                LogManager.shared.debug("reader.startReading() -> \(readerStarted), status: \(reader.status.rawValue)", component: "LocalSpeechRecognizer")
                if !readerStarted {
                    LogManager.shared.error("reader.error: \(String(describing: reader.error))", component: "LocalSpeechRecognizer")
                    completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                    return
                }

                let inputQueue = DispatchQueue(label: "audioInputQueue")
                writerInput.requestMediaDataWhenReady(on: inputQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if reader.status == .failed || reader.status == .completed {
                            LogManager.shared.debug("reader.status: \(reader.status.rawValue), error: \(String(describing: reader.error))", component: "LocalSpeechRecognizer")
                            break
                        }
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(sampleBuffer)
                        } else {
                            writerInput.markAsFinished()
                            writer.finishWriting {
                                defer { try? FileManager.default.removeItem(at: wavURL) }
                                if writer.status == .completed {
                                    LogManager.shared.info("Конвертация завершена: \(wavURL.path)", component: "LocalSpeechRecognizer")
                                    completion(.success(wavURL))
                                } else {
                                    LogManager.shared.error("Ошибка завершения writer: \(String(describing: writer.error))", component: "LocalSpeechRecognizer")
                                    completion(.failure(LocalSpeechRecognizerError.conversionFailed))
                                }
                            }
                            break
                        }
                    }
                }
            } catch {
                LogManager.shared.error("Ошибка конвертации: \(error.localizedDescription)", component: "LocalSpeechRecognizer")
                completion(.failure(error))
            }
        }
    }
    
    private func performTranscription(wavURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        LogManager.shared.info("Вызван performTranscription для файла: \(wavURL.path)", component: "LocalSpeechRecognizer")
        
        // Проверяем, что входной файл существует
        guard FileManager.default.fileExists(atPath: wavURL.path) else {
            LogManager.shared.error("Входной WAV файл не существует: \(wavURL.path)", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
            return
        }
        
        // Используем Whisper.cpp через командную строку
        let process = Process()
        
        // Путь к бинарнику в Frameworks (где есть библиотеки)
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            LogManager.shared.error("Не удалось получить путь к Frameworks", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        let bundlePath = "\(frameworksPath)/whisper-cli"
        
        LogManager.shared.debug("Проверяем путь к Whisper в Frameworks: \(bundlePath)", component: "LocalSpeechRecognizer")
        guard FileManager.default.fileExists(atPath: bundlePath) else {
            LogManager.shared.error("Whisper не найден в Frameworks по пути \(bundlePath)", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        process.executableURL = URL(fileURLWithPath: bundlePath)
        
        // Получаем выбранную модель
        let modelName = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/").appendingPathComponent(modelName)
        
        LogManager.shared.debug("Проверяем путь к Whisper в бандле: \(bundlePath)", component: "LocalSpeechRecognizer")
        guard FileManager.default.fileExists(atPath: bundlePath) else {
            LogManager.shared.error("Whisper не найден по пути \(bundlePath)", component: "LocalSpeechRecognizer")
            completion(.failure(LocalSpeechRecognizerError.modelNotFound))
            return
        }
        
        LogManager.shared.debug("Проверяем путь к модели: \(modelPath.path)", component: "LocalSpeechRecognizer")
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            LogManager.shared.error("Модель не найдена по пути \(modelPath.path)", component: "LocalSpeechRecognizer")
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
        
        LogManager.shared.info("Запускаем Whisper с аргументами: \(arguments)", component: "LocalSpeechRecognizer")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.terminationHandler = { process in
            LogManager.shared.info("Whisper завершился с кодом: \(process.terminationStatus)", component: "LocalSpeechRecognizer")
        }
        
        do {
            LogManager.shared.info("Пытаемся запустить процесс...", component: "LocalSpeechRecognizer")
            try process.run()
            LogManager.shared.info("Процесс запущен, PID: \(process.processIdentifier)", component: "LocalSpeechRecognizer")
            
            LogManager.shared.info("Ждем завершения процесса...", component: "LocalSpeechRecognizer")
            process.waitUntilExit()
            LogManager.shared.info("Процесс завершен", component: "LocalSpeechRecognizer")
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            LogManager.shared.debug("Whisper.cpp output: '\(output)'", component: "LocalSpeechRecognizer")
            
            if process.terminationStatus == 0 {
                // Новый способ: результат — это wavURL.path + ".txt"
                let outputFile = URL(fileURLWithPath: wavURL.path + ".txt")
                LogManager.shared.debug("Ищем результат в файле: \(outputFile.path)", component: "LocalSpeechRecognizer")
                
                if FileManager.default.fileExists(atPath: outputFile.path) {
                    if let result = try? String(contentsOf: outputFile, encoding: .utf8) {
                        LogManager.shared.info("Результат распознавания: '\(result)' (длина: \(result.count))", component: "LocalSpeechRecognizer")
                        let punctuatedText = self.addPunctuation(to: result)
                        LogManager.shared.info("Текст с пунктуацией: '\(punctuatedText)'", component: "LocalSpeechRecognizer")
                        completion(.success(punctuatedText))
                    } else {
                        LogManager.shared.error("Не удалось прочитать результат из файла: \(outputFile.path)", component: "LocalSpeechRecognizer")
                        completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
                    }
                } else {
                    LogManager.shared.error("Файл с результатом не найден: \(outputFile.path)", component: "LocalSpeechRecognizer")
                    completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
                }
            } else {
                LogManager.shared.error("Whisper.cpp завершился с ошибкой: \(process.terminationStatus)", component: "LocalSpeechRecognizer")
                completion(.failure(LocalSpeechRecognizerError.transcriptionFailed))
            }
        } catch {
            LogManager.shared.error("Ошибка запуска Whisper.cpp: \(error.localizedDescription)", component: "LocalSpeechRecognizer")
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
