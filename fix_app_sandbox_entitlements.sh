#!/bin/bash

# Скрипт для исправления App Sandbox entitlements для whisper-cli
# Этот скрипт добавляет необходимые entitlements для App Store валидации

set -e

echo "🔐 Исправление App Sandbox entitlements для whisper-cli..."
echo "=========================================================="

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

# Проверяем, что сертификат для подписи передан через переменную окружения
if [ -z "$SIGN_IDENTITY" ]; then
    echo "❌ Не указан сертификат для подписи. Передайте его через переменную окружения SIGN_IDENTITY."
    echo "Пример запуска: SIGN_IDENTITY=\"<Your Apple Development Certificate>\" ./fix_app_sandbox_entitlements.sh"
    exit 1
fi
echo "✅ Сертификат: $SIGN_IDENTITY"

# Создаем временный файл entitlements для whisper-cli
create_whisper_cli_entitlements() {
    local entitlements_file="/tmp/whisper-cli.entitlements"
    
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
    local whisper_cli_path="$RESOURCES_DIR/whisper-cli"
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

# Функция для переподписи библиотек (без entitlements, только для совместимости)
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
echo "🔍 Проверяю entitlements whisper-cli..."

# Проверяем, что whisper-cli имеет правильные entitlements
if codesign -d --entitlements :- "$RESOURCES_DIR/whisper-cli" 2>/dev/null | grep -q "com.apple.security.app-sandbox"; then
    echo "✅ whisper-cli имеет App Sandbox entitlement"
else
    echo "❌ whisper-cli не имеет App Sandbox entitlement"
fi

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

# Удаляем временный файл entitlements
rm -f "$ENTITLEMENTS_FILE"

echo ""
echo "🎉 Исправление App Sandbox entitlements завершено!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Пересоберите приложение в Xcode"
echo "   2. Убедитесь, что Hardened Runtime включен"
echo "   3. Протестируйте распознавание речи"
echo "   4. Попробуйте загрузить в App Store Connect"
echo ""
echo "🔒 Теперь whisper-cli имеет необходимые App Sandbox entitlements для App Store" 