//
//  WhiteNoiseApp.swift
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

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var voiceRecorder: VoiceRecorder?
    var settingsWindow: NSWindow?
    var globalMonitor: Any?
    var carbonHotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Инициализируем систему логов
        LogManager.shared.info("app_started".localized, component: .appDelegate)
        
        // Не скрываем приложение из Dock, чтобы окно отображалось
        // NSApp.setActivationPolicy(.accessory)
        
        // Запрашиваем разрешения на уведомления
        requestNotificationPermissions()
        
        // Устанавливаем делегат для уведомлений
        UNUserNotificationCenter.current().delegate = self
        
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
        
        LogManager.shared.info("app_initialization_completed".localized, component: .appDelegate)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        LogManager.shared.info("app_terminating".localized, component: .appDelegate)
        
        // Очищаем глобальный мониторинг при завершении
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            LogManager.shared.debug("global_monitor_removed".localized, component: .appDelegate)
        }
        
        // Очищаем Carbon Hot Key
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            LogManager.shared.debug("carbon_hotkey_removed".localized, component: .appDelegate)
        }
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    LogManager.shared.info("notification_permissions_granted".localized, component: .appDelegate)
                } else {
                    LogManager.shared.warning("notification_permissions_denied".localized(with: error?.localizedDescription ?? "unknown_error".localized), component: .appDelegate)
                }
            }
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
            menu.addItem(NSMenuItem(title: "stop_recording".localized, action: #selector(stopRecording), keyEquivalent: "r"))
        } else {
            menu.addItem(NSMenuItem(title: "start_recording".localized, action: #selector(startRecording), keyEquivalent: "r"))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "paste_from_clipboard".localized, action: #selector(pasteFromClipboard), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "settings".localized, action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "quit".localized, action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func registerGlobalShortcut() {
        // В sandbox режиме глобальные мониторинги могут не работать
        // Поэтому используем только локальные мониторинги и меню
        
        LogManager.shared.info("registering_shortcuts".localized, component: .appDelegate)
        
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
            LogManager.shared.info("global_shortcut_registered".localized, component: .appDelegate)
        } else {
            LogManager.shared.warning("global_monitor_unavailable".localized, component: .appDelegate)
        }
        
        // Пытаемся зарегистрировать Carbon Hot Key как дополнительный вариант
        registerCarbonHotKey()
        
        // Устанавливаем обработчик событий Carbon
        setupCarbonEventHandler()
        
        LogManager.shared.info("shortcuts_registered".localized, component: .appDelegate)
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
        LogManager.shared.info("local_shortcut_registered".localized, component: .appDelegate)
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
            LogManager.shared.info("Carbon Hot Key Cmd+Shift+V зарегистрирован успешно", component: .appDelegate)
        } else {
            LogManager.shared.error("Ошибка регистрации Carbon Hot Key: \(status)", component: .appDelegate)
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
            LogManager.shared.info("Carbon Event Handler установлен успешно", component: .appDelegate)
        } else {
            LogManager.shared.error("Ошибка установки Carbon Event Handler: \(status)", component: .appDelegate)
        }
    }
    
    @objc func toggleRecording() {
        LogManager.shared.info("toggleRecording вызван - шорткат работает!", component: .appDelegate)
        
        if voiceRecorder?.isRecording == true {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc func startRecording() {
        LogManager.shared.info("Начало записи", component: .appDelegate)
        voiceRecorder?.startRecording()
        updateStatusBarIcon(recording: true)
        updateMenu()
    }
    
    @objc func stopRecording() {
        LogManager.shared.info("Остановка записи", component: .appDelegate)
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
            LogManager.shared.debug("Глобальный мониторинг удален", component: .appDelegate)
        }
        
        // Очищаем Carbon Hot Key
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            LogManager.shared.debug("Carbon Hot Key удален", component: .appDelegate)
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
                        LogManager.shared.error("Ошибка вставки: \(output)", component: .appDelegate)
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
        
        // Добавляем информацию о приложении
        content.userInfo = ["appIcon": "WhiteNoise"]
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LogManager.shared.error("Ошибка отправки уведомления: \(error.localizedDescription)", component: .appDelegate)
            }
        }
    }
    
    func updateStatusBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: recording ? "mic.fill" : "mic", accessibilityDescription: "Voice Input")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомления даже когда приложение активно
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Обрабатываем нажатие на уведомление
        let userInfo = response.notification.request.content.userInfo
        
        if let text = userInfo["text"] as? String {
            // Если это уведомление о завершении распознавания, копируем текст в буфер обмена
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            showNotification(title: "✅ Готово", message: "Текст скопирован")
        }
        
        completionHandler()
    }
}
