#!/bin/bash

echo "🧪 Тестирование шорткатов WhiteNoise"
echo "===================================="

# Проверяем, запущено ли приложение
echo "📱 Проверка статуса приложения..."
if pgrep -f "WhiteNoise" > /dev/null; then
    echo "✅ Приложение WhiteNoise запущено"
else
    echo "❌ Приложение WhiteNoise не запущено"
    echo "🚀 Запускаю приложение..."
    # Автоматически находим и запускаем приложение
    DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
    APP_PATH=$(find "$DERIVED_DATA_PATH" -name "WhiteNoise.app" -type d 2>/dev/null | head -1)
    
    if [ -n "$APP_PATH" ]; then
        open "$APP_PATH"
    else
        echo "❌ Приложение WhiteNoise.app не найдено в DerivedData"
        exit 1
    fi
    sleep 3
fi

echo ""
echo "🎯 Тестирование шорткатов:"
echo "1. Нажмите Cmd+Shift+V для начала записи"
echo "2. Говорите в микрофон"
echo "3. Нажмите Cmd+Shift+V снова для остановки"
echo "4. Проверьте, что текст появился в активном приложении"
echo ""

echo "📋 Альтернативные способы:"
echo "- Кликните на иконку в строке состояния"
echo "- Используйте меню: Голосовой ввод (Cmd+Shift+V)"
echo "- Используйте R для записи из меню"
echo ""

echo "🔍 Проверка прав доступа..."
echo "Убедитесь, что в Системных настройках > Безопасность и конфиденциальность:"
echo "- В разделе 'Микрофон' добавлено WhiteNoise"
echo "- В разделе 'Управление компьютером' добавлено WhiteNoise"
echo "- В разделе 'Доступность' добавлен Terminal (если используете)"
echo ""

echo "💡 Если шорткаты не работают:"
echo "1. Перезапустите приложение"
echo "2. Проверьте права доступа"
echo "3. Попробуйте использовать меню в строке состояния"
echo "4. Проверьте консоль на наличие ошибок"
echo ""

echo "🎉 Тестирование завершено!" 