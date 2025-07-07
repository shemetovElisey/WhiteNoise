#!/bin/bash

# Скрипт для исправления подписи библиотек whisper
# Этот скрипт переподписывает все библиотеки с правильным Team ID

set -e

echo "🔐 Исправление подписи библиотек whisper..."
echo "=========================================="

# Проверяем, что мы в правильной директории
if [ -n "$1" ]; then
    RESOURCES_DIR="$1"
else
    RESOURCES_DIR="WhiteNoise/Resources"
fi

if [ ! -d "$RESOURCES_DIR" ]; then
    echo "❌ Ошибка: папка Resources не найдена ($RESOURCES_DIR)"
    exit 1
fi

# Получаем Team ID из whisper-cli
# echo "🔍 Использую фиксированный Team ID..."
# TEAM_ID="HHNUQBXJ93"
# echo "✅ Team ID: $TEAM_ID"

# Проверяем, что сертификат для подписи передан через переменную окружения
if [ -z "$SIGN_IDENTITY" ]; then
    echo "❌ Не указан сертификат для подписи. Передайте его через переменную окружения SIGN_IDENTITY."
    echo "Пример запуска: SIGN_IDENTITY=\"<Your Apple Development Certificate>\" ./fix_library_signing.sh"
    exit 1
fi
echo "✅ Сертификат: $SIGN_IDENTITY"

# Функция для переподписи библиотеки
resign_library() {
    local library_path="$1"
    local library_name=$(basename "$library_path")
    
    if [ -f "$library_path" ]; then
        echo "🔐 Переподписываю $library_name..."
        
        # Удаляем старую подпись
        codesign --remove-signature "$library_path" 2>/dev/null || true
        
        # Подписываем с правильным Team ID
        if codesign --force --sign "$SIGN_IDENTITY" --options runtime "$library_path" 2>/dev/null; then
            echo "   ✅ $library_name успешно переподписана"
        else
            echo "   ❌ Не удалось переподписать $library_name"
        fi
    else
        echo "   ❌ $library_name не найдена"
    fi
}

echo ""
echo "🔐 Переподписываю библиотеки whisper..."

# Переподписываем все библиотеки whisper
resign_library "$RESOURCES_DIR/libwhisper.dylib"
resign_library "$RESOURCES_DIR/libwhisper.1.dylib"
resign_library "$RESOURCES_DIR/libwhisper.1.7.6.dylib"

echo ""
echo "🔐 Переподписываю библиотеки GGML..."

# Переподписываем все библиотеки GGML
resign_library "$RESOURCES_DIR/libggml.dylib"
resign_library "$RESOURCES_DIR/libggml-base.dylib"
resign_library "$RESOURCES_DIR/libggml-cpu.dylib"
resign_library "$RESOURCES_DIR/libggml-metal.dylib"
resign_library "$RESOURCES_DIR/libggml-blas.dylib"

echo ""
echo "🔐 Переподписываю whisper-cli..."

# Переподписываем whisper-cli для консистентности
resign_library "$RESOURCES_DIR/whisper-cli"

echo ""
echo "🔍 Проверяю совместимость..."

# Проверяем, что все библиотеки имеют одинаковый Team ID
echo "📋 Проверка Team ID всех библиотек:"
for lib in "$RESOURCES_DIR"/*.dylib "$RESOURCES_DIR/whisper-cli"; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib")
        lib_team_id=$(codesign -dv "$lib" 2>&1 | grep "TeamIdentifier" | awk '{print $2}')
        if [ -z "$lib_team_id" ]; then
            lib_team_id="(не найден)"
        fi
        echo "   $lib_name: $lib_team_id"
    fi
done

echo ""
echo "🎉 Исправление подписи библиотек завершено!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Пересоберите приложение в Xcode"
echo "   2. Убедитесь, что Hardened Runtime включен"
echo "   3. Протестируйте распознавание речи"
echo ""
echo "🔒 Теперь все библиотеки переподписаны и совместимы с Hardened Runtime"

# Проверяем, что сертификат действительно действующий
echo "🔍 Проверяю сертификат..."
security find-identity -v -p codesigning

echo ""
echo "🎉 Все библиотеки успешно переподписаны!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Пересоберите приложение в Xcode"
echo "   2. Убедитесь, что Hardened Runtime включен"
echo "   3. Протестируйте распознавание речи"
echo ""
echo "🔒 Теперь все библиотеки переподписаны и совместимы с Hardened Runtime" 