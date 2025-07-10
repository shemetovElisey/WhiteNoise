//
//  LogsView.swift
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

struct LogsView: View {
    @ObservedObject private var logManager = LogManager.shared
    @State private var selectedLevel: LogLevel? = nil
    @State private var selectedComponent: String? = nil
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var showingClearAlert = false
    @State private var showingExportSuccess = false
    @State private var exportedFileURL: URL?
    
    private var filteredLogs: [LogEntry] {
        var logs = logManager.logs
        
        // Фильтр по уровню
        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }
        
        // Фильтр по компоненту
        if let component = selectedComponent {
            logs = logs.filter { $0.component == component }
        }
        
        // Фильтр по поиску
        if !searchText.isEmpty {
            logs = logs.filter { 
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.component.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return logs
    }
    
    private var availableComponents: [String] {
        Array(Set(logManager.logs.map { $0.component })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопки управления
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Системные логи")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(filteredLogs.count) из \(logManager.logs.count) записей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Очистить") {
                        showingClearAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("Экспорт") {
                        showingExportSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            // Фильтры
            VStack(spacing: 12) {
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Поиск в логах...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Фильтры по уровню и компоненту
                HStack(spacing: 16) {
                    // Фильтр по уровню
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Уровень")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Уровень", selection: $selectedLevel) {
                            Text("Все").tag(nil as LogLevel?)
                            ForEach(LogLevel.allCases, id: \.self) { level in
                                HStack {
                                    Text(level.icon)
                                    Text(level.rawValue)
                                }
                                .tag(level as LogLevel?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    
                    // Фильтр по компоненту
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Компонент")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Компонент", selection: $selectedComponent) {
                            Text("Все").tag(nil as String?)
                            ForEach(availableComponents, id: \.self) { component in
                                Text(component).tag(component as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                    
                    Spacer()
                    
                    // Настройки логирования
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Настройки")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Toggle("Включено", isOn: $logManager.isLoggingEnabled)
                                .toggleStyle(SwitchToggleStyle())
                                .scaleEffect(0.8)
                                .onChange(of: logManager.isLoggingEnabled, initial: true) { _, _ in
                                    logManager.saveSettings()
                                }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Список логов
            if filteredLogs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Логи не найдены")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if logManager.logs.isEmpty {
                        Text("Логирование отключено или нет записей")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Попробуйте изменить фильтры")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredLogs.reversed()) { entry in
                            LogEntryView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .alert("Очистить логи?", isPresented: $showingClearAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Очистить", role: .destructive) {
                logManager.clearLogs()
            }
        } message: {
            Text("Все логи будут удалены. Это действие нельзя отменить.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportLogsView(
                logManager: logManager,
                filteredLogs: filteredLogs,
                onExport: { url in
                    exportedFileURL = url
                    showingExportSuccess = true
                }
            )
        }
        .alert("Логи экспортированы", isPresented: $showingExportSuccess) {
            Button("OK") { }
            if let url = exportedFileURL {
                Button("Открыть папку") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
            }
        } message: {
            if let url = exportedFileURL {
                Text("Файл сохранен: \(url.lastPathComponent)")
            }
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.icon)
                    .font(.caption)
                
                Text(entry.level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(entry.level.color)
                
                Text(entry.component)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(entry.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(entry.level.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ExportLogsView: View {
    @ObservedObject var logManager: LogManager
    let filteredLogs: [LogEntry]
    let onExport: (URL?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var exportAllLogs = false
    @State private var includeTimestamp = true
    @State private var includeLevel = true
    @State private var includeComponent = true
    @State private var isExporting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Экспорт логов")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Настройки экспорта
                VStack(alignment: .leading, spacing: 12) {
                    Text("Настройки экспорта")
                        .font(.headline)
                    
                    Toggle("Экспортировать все логи (не только отфильтрованные)", isOn: $exportAllLogs)
                    
                    Divider()
                    
                    Text("Формат экспорта")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("Включить временные метки", isOn: $includeTimestamp)
                    Toggle("Включить уровни логирования", isOn: $includeLevel)
                    Toggle("Включить компоненты", isOn: $includeComponent)
                }
                
                Divider()
                
                // Предварительный просмотр
                VStack(alignment: .leading, spacing: 8) {
                    Text("Предварительный просмотр")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Будет экспортировано: \(exportAllLogs ? logManager.logs.count : filteredLogs.count) записей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Экспортировать") {
                    exportLogs()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func exportLogs() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let logsToExport = exportAllLogs ? logManager.logs : filteredLogs
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            
            let filename = "WhiteNoise_Logs_\(timestamp).txt"
            
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    isExporting = false
                    dismiss()
                }
                return
            }
            
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            var content = """
            ========================================
            WhiteNoise Log Export
            Generated: \(formatter.string(from: Date()))
            Total entries: \(logsToExport.count)
            ========================================
            
            """
            
            for entry in logsToExport {
                var line = ""
                
                if includeTimestamp {
                    line += "[\(entry.formattedTimestamp)] "
                }
                
                if includeLevel {
                    line += "[\(entry.level.rawValue)] "
                }
                
                if includeComponent {
                    line += "[\(entry.component)] "
                }
                
                line += entry.message
                content += line + "\n"
            }
            
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    isExporting = false
                    onExport(fileURL)
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    LogsView()
} 
