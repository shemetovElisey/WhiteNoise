#!/bin/bash

# Скрипт для настройки Hardened Runtime в проекте Xcode
# Этот скрипт настраивает необходимые параметры безопасности

set -e

echo "🔒 Настройка Hardened Runtime для проекта WhiteNoise..."

# Проверяем, что мы в правильной директории
if [ ! -f "WhiteNoise.xcodeproj/project.pbxproj" ]; then
    echo "❌ Ошибка: файл проекта Xcode не найден"
    echo "💡 Убедитесь, что вы находитесь в корневой папке проекта"
    exit 1
fi

# Проверяем, что мы на macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Ошибка: этот скрипт предназначен только для macOS"
    exit 1
fi

echo "📱 Настраиваю параметры безопасности в проекте Xcode..."

# Создаем временный файл для обновления проекта
TEMP_FILE=$(mktemp)

# Функция для обновления настроек проекта
update_project_settings() {
    local project_file="WhiteNoise.xcodeproj/project.pbxproj"
    
    # Создаем резервную копию
    cp "$project_file" "${project_file}.backup"
    echo "💾 Создана резервная копия проекта: ${project_file}.backup"
    
    # Обновляем настройки Hardened Runtime
    sed -i '' 's/ENABLE_HARDENED_RUNTIME = NO;/ENABLE_HARDENED_RUNTIME = YES;/g' "$project_file"
    sed -i '' 's/ENABLE_HARDENED_RUNTIME = "NO";/ENABLE_HARDENED_RUNTIME = "YES";/g' "$project_file"
    
    # Добавляем настройки безопасности, если их нет
    if ! grep -q "ENABLE_HARDENED_RUNTIME" "$project_file"; then
        echo "⚠️  Настройки Hardened Runtime не найдены в проекте"
        echo "💡 Вам нужно будет настроить их вручную в Xcode:"
        echo "   1. Откройте проект в Xcode"
        echo "   2. Выберите target WhiteNoise"
        echo "   3. Перейдите в Signing & Capabilities"
        echo "   4. Включите Hardened Runtime"
    else
        echo "✅ Настройки Hardened Runtime обновлены"
    fi
}

# Обновляем настройки проекта
update_project_settings

echo ""
echo "🎉 Настройка Hardened Runtime завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Откройте WhiteNoise.xcodeproj в Xcode"
echo "   2. Выберите target WhiteNoise"
echo "   3. Перейдите в Signing & Capabilities"
echo "   4. Убедитесь, что Hardened Runtime включен"
echo "   5. При необходимости добавьте исключения для библиотек whisper"
echo ""
echo "🔒 Hardened Runtime обеспечивает:"
echo "   - Защиту от выполнения кода из стека"
echo "   - Защиту от выполнения кода из кучи"
echo "   - Проверку целостности библиотек"
echo "   - Ограничение доступа к системным ресурсам"
echo ""
echo "⚠️  Если возникнут проблемы с библиотеками whisper:"
echo "   - Добавьте их в исключения Hardened Runtime"
echo "   - Или пересоберите библиотеки с поддержкой Hardened Runtime" 