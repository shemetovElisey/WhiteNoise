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
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/\(filename)")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    var fileSize: Int64? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
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

class WhisperModelManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var installedModels: [WhisperModel] = []
    @Published var availableModels: [WhisperModel] = WhisperModel.availableModels
    @Published var selectedModel: WhisperModel = WhisperModel.getDefaultModel()
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus = ""
    @Published var errorMessage: String? = nil
    
    private var downloadCompletion: ((Bool) -> Void)?
    private var currentModelPath: URL?
    
    override init() {
        super.init()
        LogManager.shared.info("WhisperModelManager инициализирован", component: "WhisperModelManager")
        refreshInstalledModels()
        loadSelectedModel()
    }
    
    func refreshInstalledModels() {
        installedModels = WhisperModel.availableModels.filter { $0.isInstalled }
        LogManager.shared.info("Обновлен список установленных моделей: \(installedModels.count) моделей", component: "WhisperModelManager")
    }
    
    func loadSelectedModel() {
        let savedFilename = UserDefaults.standard.string(forKey: "WhisperModelName") ?? WhisperModel.getDefaultModel().filename
        if let model = WhisperModel.getModel(by: savedFilename) {
            selectedModel = model
        }
    }
    
    func selectModel(_ model: WhisperModel) {
        LogManager.shared.info("Выбрана модель: \(model.displayName)", component: "WhisperModelManager")
        selectedModel = model
        UserDefaults.standard.set(model.filename, forKey: "WhisperModelName")
    }
    
    func downloadModel(_ model: WhisperModel, completion: @escaping (Bool) -> Void) {
        LogManager.shared.info("Начинаем загрузку модели: \(model.displayName)", component: "WhisperModelManager")
        
        guard let downloadURL = model.downloadURL else {
            LogManager.shared.error("Нет ссылки для загрузки модели: \(model.displayName)", component: "WhisperModelManager")
            errorMessage = "Нет ссылки для загрузки модели."
            completion(false)
            return
        }
        isDownloading = true
        downloadProgress = 0.0
        downloadStatus = "Начинаем загрузку..."
        errorMessage = nil
        downloadCompletion = completion
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let modelsDir = homeDir.appendingPathComponent("Documents/whisper-models")
        let modelPath = modelsDir.appendingPathComponent(model.filename)
        currentModelPath = modelPath
        
        // Создаем директорию, если не существует
        do {
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
            LogManager.shared.info("Директория для моделей создана/проверена: \(modelsDir.path)", component: "WhisperModelManager")
        } catch {
            LogManager.shared.error("Ошибка создания директории: \(error.localizedDescription)", component: "WhisperModelManager")
            errorMessage = "Ошибка создания директории: \(error.localizedDescription)"
            isDownloading = false
            completion(false)
            return
        }
        
        guard let url = URL(string: downloadURL) else {
            LogManager.shared.error("Некорректный URL: \(downloadURL)", component: "WhisperModelManager")
            isDownloading = false
            errorMessage = "Некорректный URL: \(downloadURL)"
            completion(false)
            return
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        LogManager.shared.info("Задача загрузки запущена для URL: \(downloadURL)", component: "WhisperModelManager")
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            if totalBytesExpectedToWrite > 0 {
                self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                self.downloadStatus = "Загружено \(Int(self.downloadProgress * 100))%"
            } else {
                self.downloadProgress = 0
                self.downloadStatus = "Загрузка..."
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let modelPath = currentModelPath else { return }
        do {
            if FileManager.default.fileExists(atPath: modelPath.path) {
                try FileManager.default.removeItem(at: modelPath)
                LogManager.shared.info("Существующий файл модели удален: \(modelPath.path)", component: "WhisperModelManager")
            }
            
            // Просто перемещаем скачанный файл
            try FileManager.default.moveItem(at: location, to: modelPath)
            LogManager.shared.info("Модель успешно сохранена: \(modelPath.path)", component: "WhisperModelManager")
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadStatus = "Загрузка завершена"
                self.refreshInstalledModels()
                self.downloadCompletion?(true)
                self.downloadCompletion = nil
            }
        } catch {
            LogManager.shared.error("Ошибка сохранения модели: \(error.localizedDescription)", component: "WhisperModelManager")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadStatus = "Ошибка сохранения"
                self.errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
                self.downloadCompletion?(false)
                self.downloadCompletion = nil
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            LogManager.shared.error("Ошибка загрузки модели: \(error.localizedDescription)", component: "WhisperModelManager")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadStatus = "Ошибка загрузки"
                self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                self.downloadCompletion?(false)
                self.downloadCompletion = nil
            }
        }
    }
    
    func deleteModel(_ model: WhisperModel) {
        LogManager.shared.info("Удаляем модель: \(model.displayName)", component: "WhisperModelManager")
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let modelPath = homeDir.appendingPathComponent("Documents/whisper-models/\(model.filename)")
        
        do {
            try FileManager.default.removeItem(at: modelPath)
            LogManager.shared.info("Модель успешно удалена: \(modelPath.path)", component: "WhisperModelManager")
            refreshInstalledModels()
        } catch {
            LogManager.shared.error("Ошибка удаления модели: \(error.localizedDescription)", component: "WhisperModelManager")
        }
    }
} 