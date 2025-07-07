#!/bin/bash

# Скрипт для исправления App Sandbox entitlements в собранном приложении
# Этот скрипт применяется к приложению в DerivedData после сборки

set -e

echo "🔐 Исправление App Sandbox entitlements в собранном приложении..."
echo "=================================================================="

# Проверяем, что путь к приложению передан
if [ -n "$1" ]; then
    APP_PATH="$1"
else
    # Пытаемся найти приложение в DerivedData
    DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
    APP_PATH=$(find "$DERIVED_DATA_PATH" -name "WhiteNoise.app" -type d 2>/dev/null | head -1)
    
    if [ -z "$APP_PATH" ]; then
        echo "❌ Ошибка: приложение WhiteNoise.app не найдено в DerivedData"
        echo "Укажите путь к приложению вручную:"
        echo "   ./fix_built_app_sandbox.sh /path/to/WhiteNoise.app"
        exit 1
    fi
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Ошибка: указанный путь не является директорией ($APP_PATH)"
    exit 1
fi

echo "✅ Приложение найдено: $APP_PATH"

# Проверяем, что сертификат для подписи передан через переменную окружения
if [ -z "$SIGN_IDENTITY" ]; then
    echo "❌ Не указан сертификат для подписи. Передайте его через переменную окружения SIGN_IDENTITY."
    echo "Пример запуска: SIGN_IDENTITY=\"<Your Apple Development Certificate>\" ./fix_built_app_sandbox.sh"
    exit 1
fi
echo "✅ Сертификат: $SIGN_IDENTITY"

# Создаем временный файл entitlements для whisper-cli
create_whisper_cli_entitlements() {
    local entitlements_file="/tmp/whisper-cli-built.entitlements"
    
    cat > "$entitlements_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>
	<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
	<array>
		<string>~/Documents/whisper-models/</string>
	</array>
</dict>
</plist>
EOF
    
    echo "$entitlements_file"
}

# Функция для переподписи whisper-cli с entitlements
resign_whisper_cli() {
    local whisper_cli_path="$APP_PATH/Contents/Resources/whisper-cli"
    local entitlements_file="$1"
    
    if [ -f "$whisper_cli_path" ]; then
        echo "🔐 Переподписываю whisper-cli с App Sandbox entitlements..."
        
        # Удаляем старую подпись
        codesign --remove-signature "$whisper_cli_path" 2>/dev/null || true
        
        # Подписываем с entitlements
        if codesign --force --sign "$SIGN_IDENTITY" --entitlements "$entitlements_file" --options runtime "$whisper_cli_path" 2>/dev/null; then
            echo "   ✅ whisper-cli успешно переподписан с App Sandbox entitlements"
        else
            echo "   ❌ Не удалось переподписать whisper-cli"
            return 1
        fi
    else
        echo "   ❌ whisper-cli не найден в $whisper_cli_path"
        return 1
    fi
}

# Функция для переподписи библиотек
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

# Функция для переподписи основного приложения
resign_main_app() {
    echo "🔐 Переподписываю основное приложение..."
    
    # Удаляем старую подпись
    codesign --remove-signature "$APP_PATH" 2>/dev/null || true
    
    # Подписываем основное приложение
    if codesign --force --sign "$SIGN_IDENTITY" --options runtime --deep "$APP_PATH" 2>/dev/null; then
        echo "   ✅ Основное приложение успешно переподписано"
    else
        echo "   ❌ Не удалось переподписать основное приложение"
        return 1
    fi
}

echo ""
echo "📝 Создаю entitlements для whisper-cli..."
ENTITLEMENTS_FILE=$(create_whisper_cli_entitlements)
echo "✅ Entitlements созданы: $ENTITLEMENTS_FILE"

echo ""
echo "🔐 Переподписываю whisper-cli с App Sandbox entitlements..."
if resign_whisper_cli "$ENTITLEMENTS_FILE"; then
    echo "✅ whisper-cli успешно переподписан"
else
    echo "❌ Ошибка при переподписи whisper-cli"
    exit 1
fi

echo ""
echo "🔐 Переподписываю библиотеки для совместимости..."

# Переподписываем все библиотеки whisper
resign_library "$APP_PATH/Contents/Resources/libwhisper.dylib"
resign_library "$APP_PATH/Contents/Resources/libwhisper.1.dylib"
resign_library "$APP_PATH/Contents/Resources/libwhisper.1.7.6.dylib"

echo ""
echo "🔐 Переподписываю библиотеки GGML..."

# Переподписываем все библиотеки GGML
resign_library "$APP_PATH/Contents/Resources/libggml.dylib"
resign_library "$APP_PATH/Contents/Resources/libggml-base.dylib"
resign_library "$APP_PATH/Contents/Resources/libggml-cpu.dylib"
resign_library "$APP_PATH/Contents/Resources/libggml-metal.dylib"
resign_library "$APP_PATH/Contents/Resources/libggml-blas.dylib"

echo ""
echo "🔐 Переподписываю основное приложение..."
if resign_main_app; then
    echo "✅ Основное приложение успешно переподписано"
else
    echo "❌ Ошибка при переподписи основного приложения"
    exit 1
fi

echo ""
echo "🔍 Проверяю entitlements whisper-cli..."

# Проверяем, что whisper-cli имеет правильные entitlements
if codesign -d --entitlements :- "$APP_PATH/Contents/Resources/whisper-cli" 2>/dev/null | grep -q "com.apple.security.app-sandbox"; then
    echo "✅ whisper-cli имеет App Sandbox entitlement"
else
    echo "❌ whisper-cli не имеет App Sandbox entitlement"
fi

echo ""
echo "🔍 Проверяю валидацию приложения..."

# Проверяем валидацию приложения
if codesign --verify --verbose=4 "$APP_PATH" 2>/dev/null; then
    echo "✅ Приложение прошло валидацию codesign"
else
    echo "❌ Приложение не прошло валидацию codesign"
fi

# Удаляем временный файл entitlements
rm -f "$ENTITLEMENTS_FILE"

echo ""
echo "🎉 Исправление App Sandbox entitlements в собранном приложении завершено!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Протестируйте приложение"
echo "   2. Попробуйте загрузить в App Store Connect"
echo "   3. Если ошибка повторится, убедитесь что Hardened Runtime включен в Xcode"
echo ""
echo "🔒 Теперь приложение готово для App Store с правильными App Sandbox entitlements" 