//
//  WhisperModel.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation

struct WhisperModel: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let displayName: String
    let size: String
    let parameters: String
    let speed: String
    let accuracy: String
    let description: String
    let downloadURL: String?
    let isRecommended: Bool
    
    static let availableModels: [WhisperModel] = [
        WhisperModel(
            filename: "ggml-tiny.bin",
            displayName: "Tiny (39 MB)",
            size: "39 MB",
            parameters: "39M",
            speed: "Очень быстро",
            accuracy: "Хорошая",
            description: "Самая быстрая модель, подходит для быстрого распознавания",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin",
            isRecommended: true
        ),
        WhisperModel(
            filename: "ggml-base.bin",
            displayName: "Base (74 MB)",
            size: "74 MB",
            parameters: "74M",
            speed: "Быстро",
            accuracy: "Лучше",
            description: "Баланс между скоростью и качеством",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin",
            isRecommended: false
        ),
        WhisperModel(
            filename: "ggml-small.bin",
            displayName: "Small (244 MB)",
            size: "244 MB",
            parameters: "244M",
            speed: "Средне",
            accuracy: "Отличная",
            description: "Высокое качество распознавания",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin",
            isRecommended: false
        ),
        WhisperModel(
            filename: "ggml-medium.bin",
            displayName: "Medium (769 MB)",
            size: "769 MB",
            parameters: "769M",
            speed: "Медленно",
            accuracy: "Превосходная",
            description: "Максимальное качество распознавания",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin",
            isRecommended: false
        ),
        WhisperModel(
            filename: "ggml-large.bin",
            displayName: "Large (1550 MB)",
            size: "1550 MB",
            parameters: "1550M",
            speed: "Очень медленно",
            accuracy: "Максимальная",
            description: "Самая точная модель, требует много ресурсов",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin",
            isRecommended: false
        ),
        WhisperModel(
            filename: "ggml-large-v2.bin",
            displayName: "Large V2 (1550 MB)",
            size: "1550 MB",
            parameters: "1550M",
            speed: "Очень медленно",
            accuracy: "Максимальная",
            description: "Улучшенная версия Large модели",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin",
            isRecommended: false
        ),
        WhisperModel(
            filename: "ggml-large-v3.bin",
            displayName: "Large V3 (1550 MB)",
            size: "1550 MB",
            parameters: "1550M",
            speed: "Очень медленно",
            accuracy: "Максимальная",
            description: "Последняя версия Large модели",
            downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin",
            isRecommended: false
        )
    ]
    
    static func getModel(by filename: String) -> WhisperModel? {
        return availableModels.first { $0.filename == filename }
    }
    
    static func getDefaultModel() -> WhisperModel {
        return availableModels.first { $0.isRecommended } ?? availableModels[0]
    }
    
    var isInstalled: Bool {
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/\(filename)")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    var fileSize: Int64? {
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/\(filename)")
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: modelPath.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    var formattedFileSize: String {
        guard let size = fileSize else { return "Не установлена" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class WhisperModelManager: ObservableObject {
    @Published var installedModels: [WhisperModel] = []
    @Published var availableModels: [WhisperModel] = WhisperModel.availableModels
    @Published var selectedModel: WhisperModel = WhisperModel.getDefaultModel()
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus = ""
    @Published var errorMessage: String? = nil
    
    init() {
        refreshInstalledModels()
        loadSelectedModel()
    }
    
    func refreshInstalledModels() {
        installedModels = WhisperModel.availableModels.filter { $0.isInstalled }
    }
    
    func loadSelectedModel() {
        let savedFilename = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        if let model = WhisperModel.getModel(by: savedFilename) {
            selectedModel = model
        }
    }
    
    func selectModel(_ model: WhisperModel) {
        selectedModel = model
        UserDefaults.standard.set(model.filename, forKey: "WhisperModelName")
    }
    
    func downloadModel(_ model: WhisperModel, completion: @escaping (Bool) -> Void) {
        guard let downloadURL = model.downloadURL else {
            errorMessage = "Нет ссылки для загрузки модели."
            completion(false)
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadStatus = "Начинаем загрузку..."
        errorMessage = nil
        
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelsDir = homeDir.appendingPathComponent("Documents/whisper-models")
        let modelPath = modelsDir.appendingPathComponent(model.filename)
        
        // Создаем директорию, если не существует
        do {
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        } catch {
            print("Ошибка создания директории: \(error)")
            errorMessage = "Ошибка создания директории: \(error.localizedDescription)"
            isDownloading = false
            completion(false)
            return
        }
        
        guard let url = URL(string: downloadURL) else {
            isDownloading = false
            errorMessage = "Некорректный URL: \(downloadURL)"
            completion(false)
            return
        }
        
        print("[WhisperModelManager] Начинаем загрузку: \(url)")
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    print("[WhisperModelManager] Ошибка загрузки: \(error)")
                    self?.downloadStatus = "Ошибка загрузки"
                    self?.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                guard let localURL = localURL else {
                    self?.downloadStatus = "Ошибка загрузки"
                    self?.errorMessage = "Не удалось получить файл после загрузки."
                    completion(false)
                    return
                }
                
                do {
                    // Перемещаем файл в нужную директорию
                    if FileManager.default.fileExists(atPath: modelPath.path) {
                        try FileManager.default.removeItem(at: modelPath)
                    }
                    try FileManager.default.moveItem(at: localURL, to: modelPath)
                    
                    self?.downloadStatus = "Загрузка завершена"
                    self?.refreshInstalledModels()
                    print("[WhisperModelManager] Модель успешно загружена: \(modelPath.path)")
                    completion(true)
                } catch {
                    print("[WhisperModelManager] Ошибка сохранения файла: \(error)")
                    self?.downloadStatus = "Ошибка сохранения"
                    self?.errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
        
        _ = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
                self?.downloadStatus = "Загружено \(Int(progress.fractionCompleted * 100))%"
            }
        }
        
        task.resume()
    }
    
    func deleteModel(_ model: WhisperModel) {
        let homeDir = URL(fileURLWithPath: "/Users/elisey")
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/\(model.filename)")
        
        do {
            try FileManager.default.removeItem(at: modelPath)
            refreshInstalledModels()
        } catch {
            print("Ошибка удаления модели: \(error)")
        }
    }
} 