#!/bin/bash

# Скрипт для добавления SwiftWhisper в проект Xcode
# Этот скрипт нужно запустить после открытия проекта в Xcode

echo "🔧 Добавление SwiftWhisper в проект WhiteNoise..."

echo ""
echo "📋 Инструкции:"
echo "1. Откройте WhiteNoise.xcodeproj в Xcode"
echo "2. Выберите проект WhiteNoise в навигаторе"
echo "3. Перейдите на вкладку 'Package Dependencies'"
echo "4. Нажмите '+' для добавления новой зависимости"
echo "5. Введите URL: https://github.com/exPHAT/SwiftWhisper"
echo "6. Выберите версию 'Up to Next Major' с минимальной версией 0.1.0"
echo "7. Нажмите 'Add Package'"
echo "8. Выберите target 'WhiteNoise' и нажмите 'Add Package'"
echo ""
echo "✅ После этого SwiftWhisper будет добавлен в проект"
echo "💡 Затем можно собрать проект (Cmd+B)"

echo ""
echo "📁 Файлы, которые нужно добавить в проект:"
echo "- WhiteNoise/SwiftWhisperRecognizer.swift"
echo "- WhiteNoise/install_swiftwhisper.sh"
echo ""
echo "🗑️ Файлы, которые можно удалить:"
echo "- WhiteNoise/WhisperKitRecognizer.swift (уже удален)"
echo "- WhiteNoise/install_whisperkit.sh"
echo "- add_whisperkit.sh"

echo ""
echo "🎯 Преимущества SwiftWhisper:"
echo "   - Простая интеграция с whisper.cpp"
echo "   - Современный Swift API с async/await"
echo "   - Поддержка CoreML для ускорения на Apple Silicon"
echo "   - Активная разработка (704 звезды на GitHub)"
echo "   - Прямая работа с .bin файлами моделей"
echo "   - Встроенная поддержка прогресса и делегатов"

echo ""
echo "🎯 Готово! Теперь можно использовать SwiftWhisper вместо whisper.cpp" 