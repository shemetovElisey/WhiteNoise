//
//  LogManager.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation
import SwiftUI

enum LogLevel: String, CaseIterable, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let component: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var formattedLog: String {
        return "[\(formattedTimestamp)] [\(level.rawValue)] [\(component)] \(message)"
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var isLoggingEnabled = true
    @Published var maxLogEntries = 1000
    
    private let queue = DispatchQueue(label: "com.whitenoise.logmanager", qos: .utility)
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func log(_ message: String, level: LogLevel = .info, component: String = "App") {
        guard isLoggingEnabled else { return }
        
        let entry = LogEntry(timestamp: Date(), level: level, message: message, component: component)
        
        DispatchQueue.main.async {
            self.logs.append(entry)
            
            // Ограничиваем количество записей
            if self.logs.count > self.maxLogEntries {
                self.logs.removeFirst(self.logs.count - self.maxLogEntries)
            }
        }
        
        // Также выводим в консоль для отладки
        print("[\(entry.formattedTimestamp)] [\(level.rawValue)] [\(component)] \(message)")
    }
    
    func debug(_ message: String, component: String = "App") {
        log(message, level: .debug, component: component)
    }
    
    func info(_ message: String, component: String = "App") {
        log(message, level: .info, component: component)
    }
    
    func warning(_ message: String, component: String = "App") {
        log(message, level: .warning, component: component)
    }
    
    func error(_ message: String, component: String = "App") {
        log(message, level: .error, component: component)
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func exportLogs() -> String {
        let header = """
        ========================================
        WhiteNoise Log Export
        Generated: \(dateFormatter.string(from: Date()))
        Total entries: \(logs.count)
        ========================================
        
        """
        
        let logContent = logs.map { $0.formattedLog }.joined(separator: "\n")
        return header + logContent
    }
    
    func exportLogsToFile() -> URL? {
        let content = exportLogs()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let filename = "WhiteNoise_Logs_\(timestamp).txt"
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            self.error("Failed to export logs to file: \(error.localizedDescription)", component: "LogManager")
            return nil
        }
    }
    
    func getLogsByLevel(_ level: LogLevel) -> [LogEntry] {
        return logs.filter { $0.level == level }
    }
    
    func getLogsByComponent(_ component: String) -> [LogEntry] {
        return logs.filter { $0.component == component }
    }
    
    func getLogsByDateRange(from: Date, to: Date) -> [LogEntry] {
        return logs.filter { $0.timestamp >= from && $0.timestamp <= to }
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        isLoggingEnabled = UserDefaults.standard.bool(forKey: "LogManager.isLoggingEnabled")
        if UserDefaults.standard.object(forKey: "LogManager.isLoggingEnabled") == nil {
            isLoggingEnabled = true // По умолчанию включено
        }
        
        maxLogEntries = UserDefaults.standard.integer(forKey: "LogManager.maxLogEntries")
        if maxLogEntries == 0 {
            maxLogEntries = 1000 // По умолчанию 1000 записей
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isLoggingEnabled, forKey: "LogManager.isLoggingEnabled")
        UserDefaults.standard.set(maxLogEntries, forKey: "LogManager.maxLogEntries")
    }
} 