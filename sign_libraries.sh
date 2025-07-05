#!/bin/bash

# Скрипт для подписи библиотек whisper с поддержкой Hardened Runtime
# Этот скрипт подписывает библиотеки для совместимости с Hardened Runtime

set -e

echo "🔐 Подпись библиотек whisper для Hardened Runtime..."

# Проверяем, что мы в правильной директории
if [ ! -d "WhiteNoise/Resources" ]; then
    echo "❌ Ошибка: папка Resources не найдена"
    echo "💡 Убедитесь, что библиотеки уже скопированы в проект"
    exit 1
fi

# Проверяем, что мы на macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Ошибка: этот скрипт предназначен только для macOS"
    exit 1
fi

RESOURCES_DIR="WhiteNoise/Resources"

echo "📦 Проверяю библиотеки в $RESOURCES_DIR..."

# Функция для подписи библиотеки
sign_library() {
    local library_path="$1"
    local library_name=$(basename "$library_path")
    
    if [ -f "$library_path" ]; then
        echo "🔐 Подписываю $library_name..."
        
        # Проверяем текущую подпись
        if codesign -dv "$library_path" 2>/dev/null; then
            echo "   ℹ️  Библиотека уже подписана"
        else
            echo "   ⚠️  Библиотека не подписана"
        fi
        
        # Подписываем библиотеку с поддержкой Hardened Runtime
        if codesign --force --sign - --options runtime "$library_path" 2>/dev/null; then
            echo "   ✅ $library_name успешно подписана"
        else
            echo "   ⚠️  Не удалось подписать $library_name (возможно, нет прав разработчика)"
            echo "   💡 Для подписи нужен сертификат разработчика Apple"
        fi
    else
        echo "   ❌ $library_name не найдена"
    fi
}

# Подписываем все библиотеки whisper
echo ""
echo "🔐 Подписываю библиотеки whisper..."

sign_library "$RESOURCES_DIR/libwhisper.dylib"
sign_library "$RESOURCES_DIR/libwhisper.1.dylib"
sign_library "$RESOURCES_DIR/libwhisper.1.7.6.dylib"

echo ""
echo "🔐 Подписываю библиотеки GGML..."

sign_library "$RESOURCES_DIR/libggml.dylib"
sign_library "$RESOURCES_DIR/libggml-base.dylib"
sign_library "$RESOURCES_DIR/libggml-cpu.dylib"
sign_library "$RESOURCES_DIR/libggml-metal.dylib"
sign_library "$RESOURCES_DIR/libggml-blas.dylib"

echo ""
echo "🔍 Проверяю совместимость с Hardened Runtime..."

# Функция для проверки совместимости
check_hardened_runtime() {
    local library_path="$1"
    local library_name=$(basename "$library_path")
    
    if [ -f "$library_path" ]; then
        echo "🔍 Проверяю $library_name..."
        
        # Проверяем, поддерживает ли библиотека Hardened Runtime
        if otool -l "$library_path" | grep -q "LC_CODE_SIGNATURE"; then
            echo "   ✅ $library_name поддерживает Hardened Runtime"
        else
            echo "   ⚠️  $library_name может не поддерживать Hardened Runtime"
        fi
        
        # Проверяем архитектуру
        if file "$library_path" | grep -q "x86_64\|arm64"; then
            echo "   ✅ $library_name имеет правильную архитектуру"
        else
            echo "   ⚠️  $library_name может иметь неподдерживаемую архитектуру"
        fi
    fi
}

# Проверяем все библиотеки
check_hardened_runtime "$RESOURCES_DIR/libwhisper.dylib"
check_hardened_runtime "$RESOURCES_DIR/libggml.dylib"

echo ""
echo "🎉 Подпись библиотек завершена!"
echo ""
echo "📋 Рекомендации:"
echo "   1. Если у вас есть сертификат разработчика Apple, используйте его для подписи"
echo "   2. В Xcode добавьте библиотеки в исключения Hardened Runtime при необходимости"
echo "   3. Убедитесь, что в настройках проекта включен Hardened Runtime"
echo ""
echo "🔒 Для полной совместимости с Hardened Runtime:"
echo "   - Все библиотеки должны быть подписаны"
echo "   - Библиотеки должны быть собраны с поддержкой Hardened Runtime"
echo "   - Приложение должно быть подписано с включенным Hardened Runtime" 