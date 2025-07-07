#!/bin/bash

# Скрипт для подготовки приложения к публикации в App Store
# Этот скрипт автоматизирует весь процесс: сборка, исправление entitlements, валидация

set -e

echo "🚀 Подготовка приложения к публикации в App Store..."
echo "=================================================="

# Проверяем, что сертификат для подписи передан через переменную окружения
if [ -z "$SIGN_IDENTITY" ]; then
    echo "❌ Не указан сертификат для подписи. Передайте его через переменную окружения SIGN_IDENTITY."
    echo "Пример запуска: SIGN_IDENTITY=\"<Your Apple Development Certificate>\" ./prepare_for_app_store.sh"
    exit 1
fi
echo "✅ Сертификат: $SIGN_IDENTITY"

# Функция для очистки предыдущих сборок
clean_build() {
    echo "🧹 Очистка предыдущих сборок..."
    xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise clean
    echo "✅ Очистка завершена"
}

# Функция для сборки Release версии
build_release() {
    echo "🔨 Сборка Release версии..."
    xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build
    echo "✅ Сборка завершена"
}

# Функция для поиска собранного приложения
find_built_app() {
    echo "🔍 Поиск собранного приложения..." >&2
    
    # Ищем все Release-билды
    RELEASE_APPS=( $(find "/Users/elisey/Library/Developer/Xcode/DerivedData" -name "WhiteNoise.app" -path "*/Release/*" -type d 2>/dev/null) )
    if [ ${#RELEASE_APPS[@]} -gt 0 ]; then
        echo "✅ Найдены Release-билды:" >&2
        for app in "${RELEASE_APPS[@]}"; do
            echo "   $app" >&2
        done
        # Выбираем самый свежий по времени модификации
        LATEST_RELEASE_APP=$(ls -td "${RELEASE_APPS[@]}" | head -1)
        echo "➡️  Использую самый свежий Release: $LATEST_RELEASE_APP" >&2
        echo "$LATEST_RELEASE_APP"
        return 0
    fi
    # Если не найдено в Release, ищем Debug
    DEBUG_APPS=( $(find "/Users/elisey/Library/Developer/Xcode/DerivedData" -name "WhiteNoise.app" -path "*/Debug/*" -type d 2>/dev/null) )
    if [ ${#DEBUG_APPS[@]} -gt 0 ]; then
        echo "⚠️  Найдены Debug-билды:" >&2
        for app in "${DEBUG_APPS[@]}"; do
            echo "   $app" >&2
        done
        LATEST_DEBUG_APP=$(ls -td "${DEBUG_APPS[@]}" | head -1)
        echo "➡️  Использую самый свежий Debug: $LATEST_DEBUG_APP" >&2
        echo "$LATEST_DEBUG_APP"
        return 0
    fi
    echo "❌ Приложение не найдено в DerivedData" >&2
    return 1
}

# Функция для проверки наличия whisper-cli
check_whisper_cli() {
    local app_path="$1"
    local whisper_cli_path="$app_path/Contents/Resources/whisper-cli"
    echo "🔎 Проверяю наличие whisper-cli по пути: $whisper_cli_path"
    if [ -f "$whisper_cli_path" ]; then
        echo "✅ whisper-cli найден в Resources ($whisper_cli_path)"
        return 0
    else
        echo "❌ whisper-cli не найден в Resources ($whisper_cli_path)"
        echo "   Содержимое папки Resources:"
        ls -la "$app_path/Contents/Resources/"
        return 1
    fi
}

# Функция для исправления App Sandbox entitlements
fix_app_sandbox() {
    local app_path="$1"
    
    echo "🔐 Исправление App Sandbox entitlements..."
    
    # Создаем временный файл entitlements для whisper-cli
    local entitlements_file="/tmp/whisper-cli-appstore.entitlements"
    
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
		<string>/Users/elisey/Documents/whisper-models/</string>
	</array>
</dict>
</plist>
EOF
    
    # Переподписываем whisper-cli с entitlements
    local whisper_cli_path="$app_path/Contents/Resources/whisper-cli"
    
    if [ -f "$whisper_cli_path" ]; then
        echo "   🔐 Переподписываю whisper-cli с App Sandbox entitlements..."
        
        # Удаляем старую подпись
        codesign --remove-signature "$whisper_cli_path" 2>/dev/null || true
        
        # Подписываем с entitlements
        if codesign --force --sign "$SIGN_IDENTITY" --entitlements "$entitlements_file" --options runtime "$whisper_cli_path" 2>/dev/null; then
            echo "   ✅ whisper-cli успешно переподписан"
        else
            echo "   ❌ Не удалось переподписать whisper-cli"
            rm -f "$entitlements_file"
            return 1
        fi
    else
        echo "   ❌ whisper-cli не найден"
        rm -f "$entitlements_file"
        return 1
    fi
    
    # Переподписываем основное приложение
    echo "   🔐 Переподписываю основное приложение..."
    
    # Удаляем старую подпись
    codesign --remove-signature "$app_path" 2>/dev/null || true
    
    # Подписываем основное приложение
    if codesign --force --sign "$SIGN_IDENTITY" --options runtime --deep "$app_path" 2>/dev/null; then
        echo "   ✅ Основное приложение успешно переподписано"
    else
        echo "   ❌ Не удалось переподписать основное приложение"
        rm -f "$entitlements_file"
        return 1
    fi
    
    # Удаляем временный файл entitlements
    rm -f "$entitlements_file"
    
    echo "✅ App Sandbox entitlements исправлены"
}

# Функция для проверки entitlements
verify_entitlements() {
    local app_path="$1"
    local whisper_cli_path="$app_path/Contents/Resources/whisper-cli"
    
    echo "🔍 Проверка entitlements..."
    
    if codesign -d --entitlements :- "$whisper_cli_path" 2>/dev/null | grep -q "com.apple.security.app-sandbox"; then
        echo "✅ whisper-cli имеет App Sandbox entitlement"
    else
        echo "❌ whisper-cli не имеет App Sandbox entitlement"
        return 1
    fi
}

# Функция для валидации приложения
validate_app() {
    local app_path="$1"
    
    echo "🔍 Валидация приложения..."
    
    if codesign --verify --verbose=4 "$app_path" 2>/dev/null; then
        echo "✅ Приложение прошло валидацию codesign"
    else
        echo "❌ Приложение не прошло валидацию codesign"
        return 1
    fi
}

# Функция для создания архива для App Store
create_archive() {
    local app_path="$1"
    
    echo "📦 Создание архива для App Store..."
    
    # Создаем папку для архива
    local archive_dir="./AppStoreArchive"
    mkdir -p "$archive_dir"
    
    # Копируем приложение в архив
    local archive_name="WhiteNoise-$(date +%Y%m%d-%H%M%S).app"
    local archive_path="$archive_dir/$archive_name"
    
    cp -R "$app_path" "$archive_path"
    
    echo "✅ Архив создан: $archive_path"
    echo "$archive_path"
}

# Основной процесс
main() {
    echo ""
    echo "📋 Начинаем процесс подготовки к App Store..."
    echo ""
    
    # Шаг 1: Очистка
    clean_build
    
    echo ""
    # Шаг 2: Сборка
    build_release
    
    echo ""
    # Шаг 3: Поиск приложения
    APP_PATH=$(find_built_app)
    if [ $? -ne 0 ]; then
        echo "❌ Не удалось найти собранное приложение"
        exit 1
    fi
    
    echo ""
    # Шаг 4: Проверка whisper-cli
    if ! check_whisper_cli "$APP_PATH"; then
        echo "❌ whisper-cli не найден в приложении"
        echo "   Убедитесь, что файл добавлен в проект и копируется при сборке"
        exit 1
    fi
    
    echo ""
    # Шаг 5: Исправление App Sandbox
    if ! fix_app_sandbox "$APP_PATH"; then
        echo "❌ Не удалось исправить App Sandbox entitlements"
        exit 1
    fi
    
    echo ""
    # Шаг 6: Проверка entitlements
    if ! verify_entitlements "$APP_PATH"; then
        echo "❌ Entitlements не применены корректно"
        exit 1
    fi
    
    echo ""
    # Шаг 7: Валидация
    if ! validate_app "$APP_PATH"; then
        echo "❌ Приложение не прошло валидацию"
        exit 1
    fi
    
    echo ""
    # Шаг 8: Создание архива
    ARCHIVE_PATH=$(create_archive "$APP_PATH")
    
    echo ""
    echo "🎉 Подготовка к App Store завершена успешно!"
    echo ""
    echo "📋 Результат:"
    echo "   Приложение: $APP_PATH"
    echo "   Архив: $ARCHIVE_PATH"
    echo ""
    echo "📋 Следующие шаги:"
    echo "   1. Откройте Xcode"
    echo "   2. Выберите Product → Archive"
    echo "   3. В Organizer выберите ваше приложение"
    echo "   4. Нажмите 'Distribute App'"
    echo "   5. Выберите 'App Store Connect'"
    echo "   6. Следуйте инструкциям для загрузки"
    echo ""
    echo "🔒 Приложение готово для App Store с правильными App Sandbox entitlements"
}

# Запуск основного процесса
main 