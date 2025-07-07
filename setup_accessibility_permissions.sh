#!/bin/bash

# Скрипт для настройки прав доступа для WhiteNoise
# Этот скрипт помогает пользователю предоставить необходимые права доступа

set -e

echo "🔐 Настройка прав доступа для WhiteNoise"
echo "========================================"
echo ""

# Получаем путь к приложению
APP_PATH=""
if [ -d "WhiteNoise.xcodeproj" ]; then
    # Мы в директории проекта, ищем собранное приложение в Xcode build directory
    XCODE_BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData"
    if [ -d "$XCODE_BUILD_DIR" ]; then
        # Ищем папку с нашим проектом
        PROJECT_DIR=$(find "$XCODE_BUILD_DIR" -name "*WhiteNoise*" -type d | head -1)
        if [ -n "$PROJECT_DIR" ]; then
            # Ищем собранное приложение
            if [ -d "$PROJECT_DIR/Build/Products/Debug/WhiteNoise.app" ]; then
                APP_PATH="$PROJECT_DIR/Build/Products/Debug/WhiteNoise.app"
            elif [ -d "$PROJECT_DIR/Build/Products/Release/WhiteNoise.app" ]; then
                APP_PATH="$PROJECT_DIR/Build/Products/Release/WhiteNoise.app"
            fi
        fi
    fi
    
    if [ -z "$APP_PATH" ]; then
        echo "❌ Собранное приложение не найдено. Сначала соберите проект в Xcode."
        echo "💡 Попробуйте: xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build"
        exit 1
    fi
else
    echo "❌ Этот скрипт должен запускаться из корневой директории проекта WhiteNoise"
    exit 1
fi

echo "✅ Найдено приложение: $APP_PATH"
echo ""

echo "📋 Для работы автоматической вставки текста необходимо предоставить права доступа:"
echo ""
echo "1. Откройте Системные настройки"
echo "2. Перейдите в Безопасность и конфиденциальность"
echo "3. Выберите вкладку Конфиденциальность"
echo "4. В левом списке выберите 'Управление компьютером'"
echo "5. Нажмите замок внизу для внесения изменений"
echo "6. Добавьте СЛЕДУЮЩИЕ приложения в список разрешенных:"
echo "   - WhiteNoise (ваше приложение)"
echo "   - Terminal (для osascript)"
echo "   - osascript (если есть в списке)"
echo ""
echo "💡 ВАЖНО: Также проверьте раздел 'Доступность' и добавьте туда Terminal"
echo ""

# Открываем системные настройки
echo "🔧 Открываю Системные настройки..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 2
echo "🔧 Открываю также раздел 'Доступность'..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "✅ Системные настройки открыты"
echo ""
echo "📝 После предоставления прав доступа:"
echo "   - Перезапустите приложение WhiteNoise"
echo "   - Попробуйте записать голос снова"
echo "   - Текст должен автоматически вставляться в активное приложение"
echo ""
echo "💡 Если права не предоставлены, текст будет копироваться в буфер обмена"
echo "   и вы сможете вставить его вручную с помощью Cmd+V"
echo ""
echo "🎉 Настройка завершена!" 