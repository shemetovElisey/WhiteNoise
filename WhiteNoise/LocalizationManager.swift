//
//  LocalizationManager.swift
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

import Foundation

/// Менеджер локализации для удобного использования локализованных строк
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    /// Получает локализованную строку по ключу
    /// - Parameter key: Ключ строки
    /// - Returns: Локализованная строка
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    /// Получает локализованную строку с форматированием
    /// - Parameters:
    ///   - key: Ключ строки
    ///   - arguments: Аргументы для форматирования
    /// - Returns: Локализованная строка с подставленными аргументами
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    /// Получает текущую локаль приложения
    var currentLocale: Locale {
        return Locale.current
    }
    
    /// Получает поддерживаемые локали
    var supportedLocales: [Locale] {
        return [Locale(identifier: "en"), Locale(identifier: "ru")]
    }
    
    /// Проверяет, поддерживается ли указанная локаль
    /// - Parameter locale: Локаль для проверки
    /// - Returns: true, если локаль поддерживается
    func isLocaleSupported(_ locale: Locale) -> Bool {
        return supportedLocales.contains { $0.identifier == locale.identifier }
    }
}

/// Расширение String для удобного использования локализации
extension String {
    /// Локализованная версия строки
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Локализованная версия строки с форматированием
    /// - Parameter arguments: Аргументы для форматирования
    /// - Returns: Локализованная строка с подставленными аргументами
    func localized(with arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(for: self, arguments: arguments)
    }
}