#!/bin/bash

# Скрипт для подписи библиотек whisper с adhoc подписью
# Это решает проблему несовместимости Team ID с основным приложением

set -e

echo "🔐 Подпись библиотек whisper с adhoc подписью..."
echo "=============================================="

RESOURCES_DIR="WhiteNoise/Resources"

# Функция для подписи библиотеки с adhoc подписью
sign_adhoc() {
    local library_path="$1"
    local library_name=$(basename "$library_path")
    
    if [ -f "$library_path" ]; then
        echo "🔐 Подписываю $library_name с adhoc подписью..."
        
        # Удаляем старую подпись
        codesign --remove-signature "$library_path" 2>/dev/null || true
        
        # Подписываем с adhoc подписью
        if codesign --force --sign - --options runtime "$library_path" 2>/dev/null; then
            echo "   ✅ $library_name успешно подписана"
        else
            echo "   ❌ Не удалось подписать $library_name"
        fi
    else
        echo "   ❌ $library_name не найдена"
    fi
}

echo ""
echo "🔐 Подписываю библиотеки whisper..."

# Подписываем все библиотеки whisper
sign_adhoc "$RESOURCES_DIR/libwhisper.dylib"
sign_adhoc "$RESOURCES_DIR/libwhisper.1.dylib"
sign_adhoc "$RESOURCES_DIR/libwhisper.1.7.6.dylib"

echo ""
echo "🔐 Подписываю библиотеки GGML..."

# Подписываем все библиотеки GGML
sign_adhoc "$RESOURCES_DIR/libggml.dylib"
sign_adhoc "$RESOURCES_DIR/libggml-base.dylib"
sign_adhoc "$RESOURCES_DIR/libggml-cpu.dylib"
sign_adhoc "$RESOURCES_DIR/libggml-metal.dylib"
sign_adhoc "$RESOURCES_DIR/libggml-blas.dylib"

echo ""
echo "🔐 Подписываю whisper-cli..."

# Подписываем whisper-cli
sign_adhoc "$RESOURCES_DIR/whisper-cli"

echo ""
echo "🔍 Проверяю подписи..."

# Проверяем, что все библиотеки имеют adhoc подпись
echo "📋 Проверка подписей всех библиотек:"
for lib in "$RESOURCES_DIR"/*.dylib "$RESOURCES_DIR/whisper-cli"; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib")
        lib_team_id=$(codesign -dv "$lib" 2>&1 | grep "TeamIdentifier" | awk '{print $2}')
        lib_signature=$(codesign -dv "$lib" 2>&1 | grep "Signature" | awk '{print $2}')
        echo "   $lib_name: TeamID=$lib_team_id, Signature=$lib_signature"
    fi
done

echo ""
echo "🎉 Подпись библиотек с adhoc подписью завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Пересоберите приложение в Xcode"
echo "   2. Протестируйте распознавание речи"
echo ""
echo "🔒 Теперь все библиотеки имеют adhoc подпись"
echo "   и совместимы с основным приложением"

chmod +x ./fix_library_signing.sh

# Автоматически находим путь к приложению и подписываем библиотеки
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "WhiteNoise.app" -type d 2>/dev/null | head -1)

if [ -n "$APP_PATH" ]; then
    FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
    if [ -d "$FRAMEWORKS_PATH" ]; then
        echo ""
        echo "🔐 Подписываю библиотеки в собранном приложении..."
        SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_library_signing.sh "$FRAMEWORKS_PATH"
    else
        echo "⚠️  Папка Frameworks не найдена в $APP_PATH"
    fi
else
    echo "⚠️  Приложение WhiteNoise.app не найдено в DerivedData"
fi 