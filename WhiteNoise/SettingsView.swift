//
//  SettingsView.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "OpenAI_API_Key") ?? ""
    @State private var showAPIKey = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedMode: RecognitionMode = RecognitionMode(rawValue: UserDefaults.standard.string(forKey: "RecognitionMode") ?? "auto") ?? .auto
    @State private var availableModels: [String] = []
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "WhisperModelName") ?? "ggml-tiny.bin"
    private let speechManager = SpeechManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Настройки Voice Input")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Режим распознавания")
                    .font(.headline)
                
                Picker("Режим", selection: $selectedMode) {
                    ForEach(speechManager.getAvailableModes(), id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Автоматический выбор: сначала OpenAI, затем локальная модель")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Модель Whisper")
                    .font(.headline)
                Picker("Модель", selection: $selectedModel.onChange { newValue in
                    UserDefaults.standard.set(newValue, forKey: "WhisperModelName")
                }) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Text("Файлы моделей ищутся в папке Documents/whisper-models")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("OpenAI API Ключ")
                    .font(.headline)
                
                HStack {
                    if showAPIKey {
                        TextField("Введите ваш OpenAI API ключ", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Введите ваш OpenAI API ключ", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: {
                        showAPIKey.toggle()
                    }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Получите API ключ на https://platform.openai.com/api-keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Горячие клавиши")
                    .font(.headline)
                
                Text("Cmd + Shift + V - Начать/остановить запись")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("R - Начать запись (из меню)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Как использовать")
                    .font(.headline)
                
                Text("1. Настройте API ключ OpenAI")
                    .font(.caption)
                Text("2. Нажмите Cmd + Shift + V или выберите из меню")
                    .font(.caption)
                Text("3. Говорите в микрофон")
                    .font(.caption)
                Text("4. Текст автоматически вставится в активное поле")
                    .font(.caption)
            }
            
            Spacer()
            
            HStack {
                Button("Сохранить") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Отмена") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .alert("Настройки", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear(perform: loadAvailableModels)
    }
    
    private func loadAvailableModels() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDir = documentsDir.appendingPathComponent("whisper-models")
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: modelsDir.path)
            let binFiles = files.filter { $0.hasSuffix(".bin") }
            self.availableModels = binFiles.sorted()
            if !binFiles.contains(selectedModel) {
                self.selectedModel = binFiles.first ?? "ggml-tiny.bin"
            }
        } catch {
            self.availableModels = ["ggml-tiny.bin"]
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "OpenAI_API_Key")
        speechManager.setRecognitionMode(selectedMode)
        UserDefaults.standard.set(selectedModel, forKey: "WhisperModelName")
        alertMessage = "Настройки сохранены!"
        showingAlert = true
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