#!/bin/bash

# Скрипт для автоматической установки и интеграции whisper в Xcode проект
# Этот скрипт запускается автоматически при сборке проекта

set -e

echo "🔧 Автоматическая установка whisper для WhiteNoise..."

# Определяем путь к корневой папке проекта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WHISPER_DIR="$PROJECT_ROOT/whisper.cpp"
RESOURCES_DIR="$PROJECT_ROOT/WhiteNoise/Resources"

echo "📁 Проект: $PROJECT_ROOT"
echo "📁 Whisper: $WHISPER_DIR"
echo "📁 Ресурсы: $RESOURCES_DIR"

# Проверяем, что whisper.cpp существует
if [ ! -d "$WHISPER_DIR" ]; then
    echo "❌ Ошибка: папка whisper.cpp не найдена"
    echo "💡 Убедитесь, что whisper.cpp клонирован в корневую папку проекта"
    exit 1
fi

# Переходим в папку whisper.cpp
cd "$WHISPER_DIR"

# Проверяем, нужно ли собирать библиотеки
if [ ! -d "build" ] || [ ! -f "build/src/libwhisper.dylib" ]; then
    echo "🔨 Собираю whisper.cpp..."
    
    # Очищаем предыдущую сборку
    if [ -d "build" ]; then
        rm -rf build
    fi
    
    # Собираем библиотеки
    make build
    
    if [ $? -eq 0 ]; then
        echo "✅ Сборка whisper.cpp завершена успешно!"
    else
        echo "❌ Ошибка при сборке whisper.cpp"
        exit 1
    fi
else
    echo "✅ Библиотеки whisper уже собраны"
fi

# Возвращаемся в корневую папку
cd "$PROJECT_ROOT"

# Создаем директорию Resources если её нет
mkdir -p "$RESOURCES_DIR"

# Копируем библиотеки
echo "📦 Копирую библиотеки в проект..."

# Основные библиотеки whisper
if [ -f "$WHISPER_DIR/build/src/libwhisper.dylib" ]; then
    cp "$WHISPER_DIR/build/src/libwhisper.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/src/libwhisper.1.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/src/libwhisper.1.7.6.dylib" "$RESOURCES_DIR/"
    echo "✅ libwhisper.dylib скопирован"
else
    echo "❌ Ошибка: libwhisper.dylib не найден"
    exit 1
fi

# Библиотеки GGML
if [ -f "$WHISPER_DIR/build/ggml/src/libggml.dylib" ]; then
    cp "$WHISPER_DIR/build/ggml/src/libggml.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/ggml/src/libggml-base.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/ggml/src/libggml-cpu.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/ggml/src/ggml-metal/libggml-metal.dylib" "$RESOURCES_DIR/"
    cp "$WHISPER_DIR/build/ggml/src/ggml-blas/libggml-blas.dylib" "$RESOURCES_DIR/"
    echo "✅ Библиотеки GGML скопированы"
else
    echo "❌ Ошибка: библиотеки GGML не найдены"
    exit 1
fi

# Заголовочный файл
if [ -f "$WHISPER_DIR/include/whisper.h" ]; then
    cp "$WHISPER_DIR/include/whisper.h" "$RESOURCES_DIR/"
    echo "✅ whisper.h скопирован"
else
    echo "❌ Ошибка: whisper.h не найден"
    exit 1
fi

# Устанавливаем правильные права доступа
chmod 644 "$RESOURCES_DIR"/*.dylib
chmod 644 "$RESOURCES_DIR"/*.h

echo ""
echo "🎉 Установка завершена успешно!"
echo "📱 Приложение готово к работе из коробки"
echo ""
echo "💡 Следующие шаги:"
echo "   1. Откройте WhiteNoise.xcodeproj в Xcode"
echo "   2. Убедитесь, что папка Resources добавлена в проект"
echo "   3. Соберите и запустите приложение (Cmd+R)" 