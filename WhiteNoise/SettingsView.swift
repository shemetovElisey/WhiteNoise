//
//  SettingsView.swift
//  WhiteNoise
//
//  Copyright (c) 2025 Elisey Shemetov. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var modelManager = WhisperModelManager()
    @State private var showingModelDetails = false
    @State private var selectedModelForDetails: WhisperModel?
    @State private var showingLogsView = false
    private let speechManager = SpeechManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("voice_input_settings".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Текущая модель
                VStack(alignment: .leading, spacing: 10) {
                    Text("current_model".localized)
                        .font(.headline)
                    
                    if modelManager.installedModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("no_models_installed".localized)
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Button("download_model".localized) {
                                showingModelDetails = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(NSColor.systemGray))
                        .cornerRadius(8)
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modelManager.selectedModel.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("model_size".localized(with: modelManager.selectedModel.formattedFileSize))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("change".localized) {
                                showingModelDetails = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(NSColor.systemGray))
                        .cornerRadius(8)
                    }
                }
                
                // Статус модели
                VStack(alignment: .leading, spacing: 10) {
                    Text("model_status".localized)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: speechManager.isLocalModelAvailable() ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(speechManager.isLocalModelAvailable() ? .green : .red)
                        Text(speechManager.isLocalModelAvailable() ? "model_available".localized : "model_unavailable".localized)
                            .foregroundColor(speechManager.isLocalModelAvailable() ? .green : .red)
                    }
                    
                    if !speechManager.isLocalModelAvailable() {
                        Text("ensure_whisper_cli_installed".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Загрузка модели
                if modelManager.isDownloading {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("downloading_model".localized)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: modelManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(modelManager.downloadStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = modelManager.errorMessage {
                    Text("error".localized(with: error))
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                // Инструкции
                VStack(alignment: .leading, spacing: 10) {
                    Text("instructions".localized)
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("instruction_1".localized)
                        Text("instruction_2".localized)
                        Text("instruction_3".localized)
                        Text("instruction_4".localized)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Системные логи
                VStack(alignment: .leading, spacing: 10) {
                    Text("system_logs".localized)
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("view_export_logs".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("open_logs".localized) {
                            showingLogsView = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section("about_app".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("app_version".localized)
                            .font(.headline)
                        Text("app_description".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("used_libraries".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("library_swiftwhisper".localized)
                                .font(.caption)
                            Text("library_whisper_cpp".localized)
                                .font(.caption)
                            Text("library_openai_whisper".localized)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("license_mit".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .frame(minWidth: 450, idealWidth: 500, maxWidth: 700, minHeight: 400, idealHeight: 500, maxHeight: 900)
        .onAppear {
            modelManager.refreshInstalledModels()
        }
        .sheet(isPresented: $showingModelDetails) {
            ModelSelectionView(modelManager: modelManager)
                .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(isPresented: $showingLogsView) {
            LogsView()
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}

struct ModelSelectionView: View {
    @ObservedObject var modelManager: WhisperModelManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDownloadAlert = false
    @State private var modelToDownload: WhisperModel?
    @State private var modelToDelete: WhisperModel?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выбор модели Whisper")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Выберите модель для распознавания речи. Большие модели обеспечивают лучшее качество, но работают медленнее.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Список моделей
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(modelManager.availableModels) { model in
                            ModelRowView(
                                model: model,
                                isInstalled: modelManager.installedModels.contains(model),
                                isSelected: modelManager.selectedModel == model,
                                isDownloading: modelManager.isDownloading && modelManager.downloadingModel == model,
                                downloadProgress: modelManager.downloadProgress,
                                onDownload: {
                                    modelToDownload = model
                                    showingDownloadAlert = true
                                },
                                onSelect: {
                                    modelManager.selectModel(model)
                                    dismiss()
                                },
                                onDelete: {
                                    modelToDelete = model
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Модели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Загрузить модель?", isPresented: $showingDownloadAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Загрузить") {
                if let model = modelToDownload {
                    modelManager.downloadModel(model)
                }
            }
        } message: {
            if let model = modelToDownload {
                Text("Модель \(model.displayName) (\(model.formattedFileSize)) будет загружена. Это может занять некоторое время.")
            }
        }
        .alert("Удалить модель?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let model = modelToDelete {
                    modelManager.deleteModel(model)
                }
            }
        } message: {
            if let model = modelToDelete {
                Text("Модель \(model.displayName) будет удалена. Это действие нельзя отменить.")
            }
        }
    }
}

struct ModelRowView: View {
    let model: WhisperModel
    let isInstalled: Bool
    let isSelected: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Размер: \(model.formattedFileSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    if isInstalled {
                        Button("Выбрать") {
                            onSelect()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSelected)
                        
                        Button("Удалить") {
                            onDelete()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    } else {
                        if isDownloading {
                            VStack(alignment: .trailing, spacing: 4) {
                                ProgressView(value: downloadProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 100)
                                
                                Text("\(Int(downloadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button("Загрузить") {
                                onDownload()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    SettingsView()
}