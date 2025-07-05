//
//  SpeechRecognizer.swift
//  WhiteNoise
//
//  Created by Shemetov Elisey on 05.07.2025.
//

import Foundation

class SpeechRecognizer {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    
    init() {
        // Получаем API ключ из UserDefaults или используем дефолтный
        self.apiKey = UserDefaults.standard.string(forKey: "OpenAI_API_Key") ?? ""
    }
    
    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(SpeechRecognizerError.noAPIKey))
            return
        }
        
        // Создаем URL запрос
        guard let url = URL(string: baseURL) else {
            completion(.failure(SpeechRecognizerError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Создаем multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Добавляем файл
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        do {
            let audioData = try Data(contentsOf: fileURL)
            body.append(audioData)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Добавляем параметры
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1".data(using: .utf8)!)
        
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json".data(using: .utf8)!)
        
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("ru".data(using: .utf8)!)
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Выполняем запрос
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(SpeechRecognizerError.noData))
                return
            }
            
            // Проверяем статус ответа
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Неизвестная ошибка"
                    completion(.failure(SpeechRecognizerError.apiError(errorMessage)))
                    return
                }
            }
            
            // Парсим JSON ответ
            do {
                let decoder = JSONDecoder()
                let transcriptionResponse = try decoder.decode(TranscriptionResponse.self, from: data)
                
                // Применяем автоматическую пунктуацию
                let punctuatedText = self.addPunctuation(to: transcriptionResponse.text)
                
                completion(.success(punctuatedText))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func addPunctuation(to text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Добавляем точку в конце, если нет знаков препинания
        if !result.isEmpty && !".!?".contains(result.last!) {
            result += "."
        }
        
        // Простые правила для улучшения пунктуации
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Заглавная буква в начале предложения
        if !result.isEmpty {
            result = String(result.prefix(1).uppercased()) + String(result.dropFirst())
        }
        
        return result
    }
}

// Модели для API ответа
struct TranscriptionResponse: Codable {
    let text: String
}

// Ошибки
enum SpeechRecognizerError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API ключ не настроен. Добавьте ключ в настройках."
        case .invalidURL:
            return "Неверный URL API"
        case .noData:
            return "Нет данных от сервера"
        case .apiError(let message):
            return "Ошибка API: \(message)"
        }
    }
} 