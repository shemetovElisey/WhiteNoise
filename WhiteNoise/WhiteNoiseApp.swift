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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Скрываем приложение из Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Создаем иконку в меню
        setupStatusBar()
        
        // Инициализируем голосовой рекордер
        voiceRecorder = VoiceRecorder()
        
        // Регистрируем глобальный шорткат
        registerGlobalShortcut()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
            button.action = #selector(toggleRecording)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Начать запись", action: #selector(startRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Настройки", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Выход", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func registerGlobalShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // Cmd + Shift + V для активации голосового ввода
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // 9 = V
                self.startRecording()
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
    }
    
    @objc func stopRecording() {
        voiceRecorder?.stopRecording()
        updateStatusBarIcon(recording: false)
    }
    
    @objc func openSettings() {
        // Показать окно настроек
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Настройки Voice Input"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView())
        settingsWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateStatusBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: recording ? "mic.fill" : "mic", accessibilityDescription: "Voice Input")
        }
    }
}
