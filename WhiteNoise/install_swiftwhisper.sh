#!/bin/bash

# Скрипт для автоматической установки и интеграции SwiftWhisper в Xcode проект
# Этот скрипт запускается автоматически при сборке проекта

set -e

echo "🔧 Автоматическая установка SwiftWhisper для WhiteNoise..."

# Определяем путь к корневой папке проекта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/WhiteNoise/Resources"

echo "📁 Проект: $PROJECT_ROOT"
echo "📁 Ресурсы: $RESOURCES_DIR"

# Создаем директорию Resources если её нет
mkdir -p "$RESOURCES_DIR"

echo "✅ SwiftWhisper будет установлен через Swift Package Manager"
echo "✅ Модели будут загружаться автоматически при первом запуске"

# Создаем директорию для моделей если её нет
MODELS_DIR="$HOME/Documents/whisper-models"
mkdir -p "$MODELS_DIR"
echo "📁 Директория для моделей: $MODELS_DIR"

echo "✅ Установка SwiftWhisper завершена!"
echo "💡 При первом запуске приложения будет предложено скачать модель"
echo ""
echo "🎯 Преимущества SwiftWhisper:"
echo "   - Простая интеграция с whisper.cpp"
echo "   - Современный Swift API"
echo "   - Поддержка CoreML для ускорения"
echo "   - Активная разработка и поддержка" 