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
    @State private var selectedComponent: LogComponent? = nil
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
                $0.component.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return logs
    }
    
    private var availableComponents: [String] {
        Array(Set(logManager.logs.map { $0.component.rawValue })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопки управления
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("logs".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(filteredLogs.count) из \(logManager.logs.count) записей")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("clear_logs".localized) {
                        showingClearAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("export_logs".localized) {
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
                    
                    Text("no_logs_available".localized)
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
        .alert("clear_logs_confirmation".localized, isPresented: $showingClearAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("clear".localized, role: .destructive) {
                logManager.clearLogs()
            }
        }
        .alert("logs_exported".localized(with: exportedFileURL?.path ?? ""), isPresented: $showingExportSuccess) {
            Button("OK") { }
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: LogExportDocument(logs: filteredLogs),
            contentType: .plainText,
            defaultFilename: "whitenoise_logs_\(Date().ISO8601String()).txt"
        ) { result in
            switch result {
            case .success(let url):
                exportedFileURL = url
                showingExportSuccess = true
            case .failure(let error):
                print("Export failed: \(error)")
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
                    .foregroundColor(entry.level.color)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("[\(entry.component.rawValue)]")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.systemGray5))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(entry.message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct LogExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    let logs: [LogEntry]
    
    init(logs: [LogEntry]) {
        self.logs = logs
    }
    
    init(configuration: ReadConfiguration) throws {
        logs = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let logText = logs.reversed().map { entry in
            "[\(entry.timestamp)] [\(entry.level.rawValue.uppercased())] [\(entry.component.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
        
        let data = logText.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

#Preview {
    LogsView()
}