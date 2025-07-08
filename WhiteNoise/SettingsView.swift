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
                Text("Настройки Voice Input")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Текущая модель
                VStack(alignment: .leading, spacing: 10) {
                    Text("Текущая модель")
                        .font(.headline)
                    
                    if modelManager.installedModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Нет установленных моделей")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Button("Загрузить модель") {
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
                                
                                Text("Размер: \(modelManager.selectedModel.formattedFileSize)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Изменить") {
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
                    Text("Статус модели")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: speechManager.isLocalModelAvailable() ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(speechManager.isLocalModelAvailable() ? .green : .red)
                        Text(speechManager.isLocalModelAvailable() ? "Модель доступна" : "Модель недоступна")
                            .foregroundColor(speechManager.isLocalModelAvailable() ? .green : .red)
                    }
                    
                    if !speechManager.isLocalModelAvailable() {
                        Text("Убедитесь, что whisper-cli и выбранная модель установлены")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Загрузка модели
                if modelManager.isDownloading {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Загрузка модели")
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
                    Text("Ошибка: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                // Инструкции
                VStack(alignment: .leading, spacing: 10) {
                    Text("Инструкции")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Нажмите Cmd+Shift+V для начала записи")
                        Text("• Говорите четко в микрофон")
                        Text("• Нажмите Cmd+Shift+V снова для остановки")
                        Text("• Распознанный текст будет скопирован в буфер обмена — вставьте его вручную (Cmd+V)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Системные логи
                VStack(alignment: .leading, spacing: 10) {
                    Text("Системные логи")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Просматривайте и экспортируйте системные логи для диагностики проблем")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Открыть логи") {
                            showingLogsView = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section("О приложении") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WhiteNoise v1.0")
                            .font(.headline)
                        Text("Приложение для распознавания речи")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("Используемые библиотеки:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• SwiftWhisper - распознавание речи")
                                .font(.caption)
                            Text("• whisper.cpp - базовая библиотека")
                                .font(.caption)
                            Text("• OpenAI Whisper - модели ML")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("Лицензия: MIT")
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
                
                // Прогресс загрузки
                if modelManager.isDownloading {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Загрузка модели")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: modelManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(modelManager.downloadStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                                    }
                .padding()
                .background(Color(NSColor.systemGray))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Отображение ошибок
            if let error = modelManager.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ошибка загрузки")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Список моделей
                ScrollView {
                    if modelManager.availableModels.isEmpty {
                        VStack(spacing: 20) {
                            Text("Нет доступных моделей")
                                .foregroundColor(.secondary)
                                .padding()
                            Button("Загрузить tiny-модель") {
                                if let tiny = WhisperModel.getModel(by: "ggml-tiny.bin") {
                                    modelManager.downloadModel(tiny) { _ in }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        LazyVStack(spacing: 12) {
                            // Отладочный вывод
                            Text("Моделей: \(modelManager.availableModels.count)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            ForEach(modelManager.availableModels) { model in
                                ModelCardView(
                                    model: model,
                                    isSelected: modelManager.selectedModel.filename == model.filename,
                                    onSelect: {
                                        if model.isInstalled {
                                            modelManager.selectModel(model)
                                            dismiss()
                                        } else {
                                            modelToDownload = model
                                            showingDownloadAlert = true
                                        }
                                    },
                                    onDownload: {
                                        modelToDownload = model
                                        showingDownloadAlert = true
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
            }
            .frame(minWidth: 500, idealWidth: 600, maxWidth: 700, minHeight: 400, idealHeight: 500, maxHeight: 700)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
                    modelManager.downloadModel(model) { success in
                        if success {
                            modelManager.selectModel(model)
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            if let model = modelToDownload {
                Text("Загрузить модель \(model.displayName)? Размер файла: \(model.size)")
            }
        }
        .alert("Удалить модель?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let model = modelToDelete {
                    let wasSelected = modelManager.selectedModel.filename == model.filename
                    modelManager.deleteModel(model)
                    modelManager.refreshInstalledModels()
                    // Если удалили выбранную модель — выбрать другую или сбросить
                    if wasSelected {
                        if let first = modelManager.installedModels.first {
                            modelManager.selectModel(first)
                        } else {
                            // Нет моделей — сбросить выбор
                            let def = WhisperModel.getDefaultModel()
                            modelManager.selectedModel = def
                            UserDefaults.standard.set(def.filename, forKey: "WhisperModelName")
                        }
                    }
                }
            }
        } message: {
            if let model = modelToDelete {
                Text("Удалить модель \(model.displayName)? Файл будет удалён из папки.")
            }
        }
    }
}

struct ModelCardView: View {
    let model: WhisperModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок и статус
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            // Характеристики
            HStack(spacing: 16) {
                CharacteristicView(title: "Скорость", value: model.speed, icon: "speedometer")
                CharacteristicView(title: "Точность", value: model.accuracy, icon: "target")
                CharacteristicView(title: "Параметры", value: model.parameters, icon: "cpu")
            }
            
            // Действия
            HStack {
                if model.isInstalled {
                    Button(isSelected ? "Выбрана" : "Выбрать") {
                        onSelect()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSelected)
                    if !isSelected {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                } else {
                    Button("Загрузить") {
                        onDownload()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if model.isInstalled {
                    Text("Установлена")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Не установлена")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct CharacteristicView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
} 