#!/bin/bash

# Скрипт для автоматического копирования библиотек whisper в Xcode проект
# Этот скрипт должен запускаться при сборке проекта

set -e

# Пути к директориям
WHISPER_BUILD_DIR="whisper.cpp/build"
PROJECT_RESOURCES_DIR="WhiteNoise/Resources"
PROJECT_DIR="WhiteNoise"

# Находим путь к Resources внутри .app
APP_RESOURCES_PATH=$(find ~/Library/Developer/Xcode/DerivedData/ -type d -name Resources | grep WhiteNoise.app | head -1)

if [ -z "$APP_RESOURCES_PATH" ]; then
  echo "❌ Не удалось найти Resources внутри .app. Соберите проект в Xcode хотя бы один раз."
  exit 1
fi

echo "🔄 Копирование библиотек whisper в проект..."

# Создаем директорию Resources если её нет
mkdir -p "$PROJECT_RESOURCES_DIR"

# Копируем основные библиотеки whisper
if [ -f "$WHISPER_BUILD_DIR/src/libwhisper.dylib" ]; then
    echo "📦 Копирую libwhisper.dylib..."
    cp "$WHISPER_BUILD_DIR/src/libwhisper.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/src/libwhisper.1.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/src/libwhisper.1.7.6.dylib" "$PROJECT_RESOURCES_DIR/"
else
    echo "❌ Ошибка: libwhisper.dylib не найден в $WHISPER_BUILD_DIR/src/"
    echo "💡 Убедитесь, что whisper.cpp собран командой 'make build'"
    exit 1
fi

# Копируем библиотеки GGML
if [ -f "$WHISPER_BUILD_DIR/ggml/src/libggml.dylib" ]; then
    echo "📦 Копирую библиотеки GGML..."
    cp "$WHISPER_BUILD_DIR/ggml/src/libggml.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/ggml/src/libggml-base.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/ggml/src/libggml-cpu.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/ggml/src/ggml-metal/libggml-metal.dylib" "$PROJECT_RESOURCES_DIR/"
    cp "$WHISPER_BUILD_DIR/ggml/src/ggml-blas/libggml-blas.dylib" "$PROJECT_RESOURCES_DIR/"
else
    echo "❌ Ошибка: библиотеки GGML не найдены"
    exit 1
fi

# Копируем заголовочный файл
if [ -f "whisper.cpp/include/whisper.h" ]; then
    echo "📦 Копирую whisper.h..."
    cp "whisper.cpp/include/whisper.h" "$PROJECT_RESOURCES_DIR/"
else
    echo "❌ Ошибка: whisper.h не найден"
    exit 1
fi

# Устанавливаем правильные права доступа
chmod 644 "$PROJECT_RESOURCES_DIR"/*.dylib
chmod 644 "$PROJECT_RESOURCES_DIR"/*.h

echo "✅ Все библиотеки успешно скопированы в $PROJECT_RESOURCES_DIR"

# --- АВТОМАТИЧЕСКОЕ КОПИРОВАНИЕ В .app ---
echo "🔄 Копирую .dylib в Resources внутри .app: $APP_RESOURCES_PATH"
cp "$PROJECT_RESOURCES_DIR"/*.dylib "$APP_RESOURCES_PATH/"
echo "✅ Все .dylib скопированы в .app/Contents/Resources"

echo "📱 Приложение готово к работе из коробки!" 