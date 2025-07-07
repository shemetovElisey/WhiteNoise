#!/bin/bash

echo "🔐 Проверка прав доступа для WhiteNoise"
echo "======================================="

# Проверяем права на микрофон
echo "🎤 Проверка прав на микрофон..."
if tccutil reset Microphone 2>/dev/null; then
    echo "✅ Права на микрофон сброшены"
else
    echo "⚠️  Не удалось сбросить права на микрофон"
fi

# Проверяем права на управление компьютером
echo "🖥️  Проверка прав на управление компьютером..."
if tccutil reset AppleEvents 2>/dev/null; then
    echo "✅ Права на управление компьютером сброшены"
else
    echo "⚠️  Не удалось сбросить права на управление компьютером"
fi

# Проверяем права на доступность
echo "♿ Проверка прав на доступность..."
if tccutil reset Accessibility 2>/dev/null; then
    echo "✅ Права на доступность сброшены"
else
    echo "⚠️  Не удалось сбросить права на доступность"
fi

echo ""
echo "🔧 Открываю Системные настройки для настройки прав..."
echo ""

# Открываем системные настройки
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
sleep 2
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 2
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AppleEvents"

echo ""
echo "📋 Инструкции по настройке:"
echo "1. В разделе 'Микрофон' добавьте WhiteNoise"
echo "2. В разделе 'Управление компьютером' добавьте WhiteNoise"
echo "3. В разделе 'Доступность' добавьте Terminal (если нужно)"
echo "4. Перезапустите приложение WhiteNoise"
echo ""

echo "🎯 После настройки прав:"
echo "- Шорткат Cmd+Shift+V должен работать"
echo "- Автоматическая вставка текста должна работать"
echo "- Уведомления должны появляться"
echo ""

echo "✅ Настройка завершена!" 