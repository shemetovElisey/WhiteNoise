//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import SwiftUI
import AppKit

@main
struct WhiteNoiseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var voiceRecorder: VoiceRecorder?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Не скрываем приложение из Dock, чтобы окно отображалось
        // NSApp.setActivationPolicy(.accessory)
        
        // Создаем иконку в меню
        setupStatusBar()
        
        // Инициализируем голосовой рекордер
        voiceRecorder = VoiceRecorder()
        
        // Регистрируем глобальный шорткат
        registerGlobalShortcut()
        
        // Показываем окно настроек при первом запуске
        showSettingsOnFirstLaunch()
        
        // Подписываемся на уведомления об изменении состояния записи
        NotificationCenter.default.addObserver(self, selector: #selector(recordingStateChanged), name: .recordingStateChanged, object: nil)
    }
    
    func showSettingsOnFirstLaunch() {
        let hasLaunchedKey = "HasLaunchedBefore"
        let launched = UserDefaults.standard.bool(forKey: hasLaunchedKey)
        if !launched {
            openSettings()
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
            button.action = #selector(toggleRecording)
            button.target = self
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        if voiceRecorder?.isRecording == true {
            menu.addItem(NSMenuItem(title: "Остановить запись", action: #selector(stopRecording), keyEquivalent: "r"))
        } else {
            menu.addItem(NSMenuItem(title: "Начать запись", action: #selector(startRecording), keyEquivalent: "r"))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Вставить из буфера обмена", action: #selector(pasteFromClipboard), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "Настройки", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Выход", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func registerGlobalShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + V для активации голосового ввода
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // 9 = V
                DispatchQueue.main.async {
                    self?.toggleRecording()
                }
            }
        }
    }
    
    @objc func toggleRecording() {
        if voiceRecorder?.isRecording == true {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc func startRecording() {
        voiceRecorder?.startRecording()
        updateStatusBarIcon(recording: true)
        updateMenu()
    }
    
    @objc func stopRecording() {
        voiceRecorder?.stopRecording()
        updateStatusBarIcon(recording: false)
        updateMenu()
    }
    
    @objc func recordingStateChanged() {
        DispatchQueue.main.async {
            self.updateMenu()
            self.updateStatusBarIcon(recording: self.voiceRecorder?.isRecording == true)
        }
    }
    
    @objc func openSettings() {
        // Показать окно настроек
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки Voice Input"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // Пытаемся вставить текст
            let script = """
            tell application "System Events"
                keystroke "\(text)"
            end tell
            """
            
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        self.showNotification(title: "WhiteNoise", message: "Текст вставлен: \(text.prefix(30))...")
                    } else {
                        self.showNotification(title: "WhiteNoise - Ошибка", message: "Не удалось вставить текст. Используйте Cmd+V вручную.")
                        print("Ошибка вставки: \(output)")
                    }
                }
            }
            
            do {
                try task.run()
            } catch {
                showNotification(title: "WhiteNoise - Ошибка", message: "Ошибка запуска вставки: \(error.localizedDescription)")
            }
        } else {
            showNotification(title: "WhiteNoise", message: "Буфер обмена пуст")
        }
    }
    
    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func updateStatusBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: recording ? "mic.fill" : "mic", accessibilityDescription: "Voice Input")
        }
    }
}
