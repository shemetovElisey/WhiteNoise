//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import SwiftUI
import AppKit
import Carbon
import UserNotifications

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
    var globalMonitor: Any?
    var carbonHotKeyRef: EventHotKeyRef?
    
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
    
    func applicationWillTerminate(_ notification: Notification) {
        // Очищаем глобальный мониторинг при завершении
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            print("[AppDelegate] Глобальный мониторинг удален при завершении")
        }
        
        // Очищаем Carbon Hot Key
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            print("[AppDelegate] Carbon Hot Key удален при завершении")
        }
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
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Voice Input")
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
        // В sandbox режиме глобальные мониторинги могут не работать
        // Поэтому используем только локальные мониторинги и меню
        
        print("[AppDelegate] Регистрация шорткатов...")
        
        // Регистрируем локальный мониторинг
        registerLocalShortcut()
        
        // Пытаемся зарегистрировать глобальный мониторинг (может не работать в sandbox)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + V для активации голосового ввода
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // 9 = V
                DispatchQueue.main.async {
                    self?.toggleRecording()
                }
            }
        }
        
        if globalMonitor != nil {
            print("[AppDelegate] Глобальный шорткат Cmd+Shift+V зарегистрирован успешно")
        } else {
            print("[AppDelegate] Глобальный мониторинг недоступен (sandbox ограничения)")
        }
        
        // Пытаемся зарегистрировать Carbon Hot Key как дополнительный вариант
        registerCarbonHotKey()
        
        // Устанавливаем обработчик событий Carbon
        setupCarbonEventHandler()
        
        print("[AppDelegate] Шорткаты зарегистрированы. Используйте меню в строке состояния как альтернативу.")
        
        // Показываем уведомление о готовности
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNotification(title: "WhiteNoise", message: "Приложение готово! Используйте Cmd+Shift+V или меню в строке состояния.")
        }
    }
    
    func registerLocalShortcut() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + V для активации голосового ввода
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // 9 = V
                DispatchQueue.main.async {
                    self?.toggleRecording()
                }
                return nil // Поглощаем событие
            }
            return event
        }
        print("[AppDelegate] Локальный шорткат Cmd+Shift+V зарегистрирован")
    }
    
    func registerCarbonHotKey() {
        // Регистрируем Carbon Hot Key для Cmd+Shift+V
        let signature = OSType("wnse".utf8.reduce(0) { ($0 << 8) + OSType($1) })
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V), // V key
            UInt32(cmdKey | shiftKey), // Cmd + Shift
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &carbonHotKeyRef
        )
        
        if status == noErr {
            print("[AppDelegate] Carbon Hot Key Cmd+Shift+V зарегистрирован успешно")
        } else {
            print("[AppDelegate] Ошибка регистрации Carbon Hot Key: \(status)")
        }
    }
    
    func setupCarbonEventHandler() {
        // Устанавливаем обработчик событий Carbon
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let error = GetEventParameter(
                    theEvent,
                    OSType(kEventParamDirectObject),
                    OSType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                let expectedSignature = OSType("wnse".utf8.reduce(0) { ($0 << 8) + OSType($1) })
                if error == noErr && hotKeyID.signature == expectedSignature {
                    DispatchQueue.main.async {
                        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                            appDelegate.toggleRecording()
                        }
                    }
                }
                
                return CallNextEventHandler(nextHandler, theEvent)
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        if status == noErr {
            print("[AppDelegate] Carbon Event Handler установлен успешно")
        } else {
            print("[AppDelegate] Ошибка установки Carbon Event Handler: \(status)")
        }
    }
    
    @objc func toggleRecording() {
        print("[AppDelegate] toggleRecording вызван - шорткат работает!")
        
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
        // Очищаем глобальный мониторинг
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            print("[AppDelegate] Глобальный мониторинг удален")
        }
        
        // Очищаем Carbon Hot Key
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            print("[AppDelegate] Carbon Hot Key удален")
        }
        
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
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func updateStatusBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: recording ? "mic.fill" : "mic", accessibilityDescription: "Voice Input")
        }
    }
}
