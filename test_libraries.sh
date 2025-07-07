#!/bin/bash

echo "🔍 Тестирование библиотек whisper..."
echo "===================================="

# Автоматически находим путь к приложению
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "WhiteNoise.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Приложение WhiteNoise.app не найдено в DerivedData"
    exit 1
fi
RESOURCES_PATH="$APP_PATH/Contents/Resources"

echo "📱 Проверка приложения: $APP_PATH"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Приложение не найдено"
    exit 1
fi

echo "📦 Проверка ресурсов: $RESOURCES_PATH"
if [ ! -d "$RESOURCES_PATH" ]; then
    echo "❌ Папка ресурсов не найдена"
    exit 1
fi

echo ""
echo "🔧 Проверка библиотек:"
for lib in libwhisper.dylib libggml.dylib libggml-base.dylib libggml-cpu.dylib libggml-metal.dylib libggml-blas.dylib; do
    if [ -f "$RESOURCES_PATH/$lib" ]; then
        echo "✅ $lib найден"
        # Проверяем подпись
        if codesign -dv "$RESOURCES_PATH/$lib" 2>/dev/null | grep -q "Apple Development"; then
            echo "   ✅ Подписан"
        else
            echo "   ⚠️  Не подписан"
        fi
    else
        echo "❌ $lib не найден"
    fi
done

echo ""
echo "🎯 Проверка whisper-cli:"
if [ -f "$RESOURCES_PATH/whisper-cli" ]; then
    echo "✅ whisper-cli найден"
    if [ -x "$RESOURCES_PATH/whisper-cli" ]; then
        echo "   ✅ Исполняемый"
    else
        echo "   ❌ Не исполняемый"
    fi
    # Проверяем подпись
    if codesign -dv "$RESOURCES_PATH/whisper-cli" 2>/dev/null | grep -q "Apple Development"; then
        echo "   ✅ Подписан"
    else
        echo "   ⚠️  Не подписан"
    fi
else
    echo "❌ whisper-cli не найден"
fi

echo ""
echo "🔗 Проверка зависимостей whisper-cli:"
if [ -f "$RESOURCES_PATH/whisper-cli" ]; then
    echo "Зависимости:"
    otool -L "$RESOURCES_PATH/whisper-cli" | grep -E "(whisper|ggml)" || echo "   Нет зависимостей whisper/ggml"
fi

echo ""
echo "🧪 Тест запуска whisper-cli:"
if [ -f "$RESOURCES_PATH/whisper-cli" ]; then
    echo "Попытка запуска whisper-cli --help..."
    timeout 5s "$RESOURCES_PATH/whisper-cli" --help 2>&1 | head -5
    if [ $? -eq 0 ]; then
        echo "✅ whisper-cli запускается успешно"
    else
        echo "❌ Ошибка запуска whisper-cli"
    fi
else
    echo "❌ whisper-cli не найден для тестирования"
fi 