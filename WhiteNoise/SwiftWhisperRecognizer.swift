//
//  SwiftWhisperRecognizer.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import AVFoundation
import SwiftWhisper

class SwiftWhisperRecognizer: NSObject {
    private var whisper: Whisper?
    private var isInitialized = false
    
    override init() {
        super.init()
        LogManager.shared.info("SwiftWhisperRecognizer инициализирован", component: "SwiftWhisperRecognizer")
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        LogManager.shared.info("Начинаем транскрипцию файла: \(fileURL.path)", component: "SwiftWhisperRecognizer")
        
        // Инициализируем SwiftWhisper если еще не инициализирован
        if !isInitialized {
            initializeSwiftWhisper { [weak self] result in
                switch result {
                case .success:
                    self?.performTranscription(fileURL: fileURL, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            performTranscription(fileURL: fileURL, completion: completion)
        }
    }
    
    private func initializeSwiftWhisper(completion: @escaping (Result<Void, Error>) -> Void) {
        LogManager.shared.info("Инициализируем SwiftWhisper...", component: "SwiftWhisperRecognizer")
        
        // Получаем выбранную модель
        let modelName = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/").appendingPathComponent(modelName)
        
        LogManager.shared.debug("Проверяем путь к модели: \(modelPath.path)", component: "SwiftWhisperRecognizer")
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            LogManager.shared.error("Модель не найдена по пути \(modelPath.path)", component: "SwiftWhisperRecognizer")
            completion(.failure(SwiftWhisperRecognizerError.modelNotFound))
            return
        }
        
        // Инициализируем SwiftWhisper
        do {
            whisper = try Whisper(fromFileURL: modelPath)
            whisper?.delegate = self
            isInitialized = true
            
            LogManager.shared.info("SwiftWhisper успешно инициализирован", component: "SwiftWhisperRecognizer")
            completion(.success(()))
        } catch {
            LogManager.shared.error("Ошибка инициализации SwiftWhisper: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
            completion(.failure(error))
        }
    }
    
    private func performTranscription(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        LogManager.shared.info("Выполняем транскрипцию файла: \(fileURL.path)", component: "SwiftWhisperRecognizer")
        
        guard let whisper = whisper else {
            LogManager.shared.error("SwiftWhisper не инициализирован", component: "SwiftWhisperRecognizer")
            completion(.failure(SwiftWhisperRecognizerError.notInitialized))
            return
        }
        
        // Проверяем, что файл существует
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            LogManager.shared.error("Файл не существует: \(fileURL.path)", component: "SwiftWhisperRecognizer")
            completion(.failure(SwiftWhisperRecognizerError.fileNotFound))
            return
        }
        
        // Конвертируем аудио в 16kHz PCM
        convertAudioToPCM(fileURL: fileURL) { [weak self] result in
            switch result {
            case .success(let audioFrames):
                LogManager.shared.info("Аудио конвертировано в PCM, начинаем транскрипцию...", component: "SwiftWhisperRecognizer")
                
                Task {
                    do {
                        let segments = try await whisper.transcribe(audioFrames: audioFrames)
                        
                        LogManager.shared.info("SwiftWhisper транскрипция завершена", component: "SwiftWhisperRecognizer")
                        
                        // Извлекаем текст из сегментов
                        let transcribedText = segments.map { $0.text }.joined(separator: " ")
                        let punctuatedText = self?.addPunctuation(to: transcribedText) ?? transcribedText
                        
                        LogManager.shared.info("Результат распознавания: '\(punctuatedText)' (длина: \(punctuatedText.count))", component: "SwiftWhisperRecognizer")
                        
                        completion(.success(punctuatedText))
                    } catch {
                        LogManager.shared.error("Ошибка транскрипции SwiftWhisper: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                LogManager.shared.error("Ошибка конвертации аудио: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
                completion(.failure(error))
            }
        }
    }
    
    private func convertAudioToPCM(fileURL: URL, completion: @escaping (Result<[Float], Error>) -> Void) {
        LogManager.shared.info("Конвертируем аудио в 16kHz PCM...", component: "SwiftWhisperRecognizer")
        
        let asset = AVURLAsset(url: fileURL)
        asset.loadTracks(withMediaType: .audio) { tracks, error in
            guard let track = tracks?.first else {
                LogManager.shared.error("Нет аудиотреков в файле: \(fileURL.path)", component: "SwiftWhisperRecognizer")
                completion(.failure(SwiftWhisperRecognizerError.conversionFailed))
                return
            }
            
            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000, // SwiftWhisper требует 16kHz
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
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
                let writer = try AVAssetWriter(outputURL: tempURL, fileType: .wav)
                let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
                writer.add(writerInput)
                
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                
                let readerStarted = reader.startReading()
                if !readerStarted {
                    LogManager.shared.error("Ошибка запуска reader: \(String(describing: reader.error))", component: "SwiftWhisperRecognizer")
                    completion(.failure(SwiftWhisperRecognizerError.conversionFailed))
                    return
                }
                
                let inputQueue = DispatchQueue(label: "audioInputQueue")
                writerInput.requestMediaDataWhenReady(on: inputQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if reader.status == .failed || reader.status == .completed {
                            break
                        }
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(sampleBuffer)
                        } else {
                            writerInput.markAsFinished()
                            writer.finishWriting {
                                defer { try? FileManager.default.removeItem(at: tempURL) }
                                
                                if writer.status == .completed {
                                    // Читаем WAV файл и конвертируем в PCM
                                    do {
                                        let data = try Data(contentsOf: tempURL)
                                        let floats = stride(from: 44, to: data.count, by: 2).map {
                                            return data[$0..<$0 + 2].withUnsafeBytes {
                                                let short = Int16(littleEndian: $0.load(as: Int16.self))
                                                return max(-1.0, min(Float(short) / 32767.0, 1.0))
                                            }
                                        }
                                        
                                        LogManager.shared.info("Аудио успешно конвертировано в PCM, \(floats.count) фреймов", component: "SwiftWhisperRecognizer")
                                        completion(.success(floats))
                                    } catch {
                                        LogManager.shared.error("Ошибка чтения WAV файла: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
                                        completion(.failure(error))
                                    }
                                } else {
                                    LogManager.shared.error("Ошибка завершения writer: \(String(describing: writer.error))", component: "SwiftWhisperRecognizer")
                                    completion(.failure(SwiftWhisperRecognizerError.conversionFailed))
                                }
                            }
                            break
                        }
                    }
                }
            } catch {
                LogManager.shared.error("Ошибка конвертации: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
                completion(.failure(error))
            }
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

// MARK: - WhisperDelegate
extension SwiftWhisperRecognizer: WhisperDelegate {
    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        LogManager.shared.debug("Прогресс транскрипции: \(Int(progress * 100))%", component: "SwiftWhisperRecognizer")
    }
    
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        let newText = segments.map { $0.text }.joined(separator: " ")
        LogManager.shared.debug("Новые сегменты: '\(newText)'", component: "SwiftWhisperRecognizer")
    }
    
    func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
        LogManager.shared.info("Транскрипция завершена, всего сегментов: \(segments.count)", component: "SwiftWhisperRecognizer")
    }
    
    func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
        LogManager.shared.error("Ошибка SwiftWhisper: \(error.localizedDescription)", component: "SwiftWhisperRecognizer")
    }
}

enum SwiftWhisperRecognizerError: Error, LocalizedError {
    case modelNotFound
    case notInitialized
    case fileNotFound
    case conversionFailed
    case transcriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Локальная модель не найдена"
        case .notInitialized:
            return "SwiftWhisper не инициализирован"
        case .fileNotFound:
            return "Аудиофайл не найден"
        case .conversionFailed:
            return "Ошибка конвертации аудио"
        case .transcriptionFailed:
            return "Ошибка распознавания речи"
        }
    }
} 