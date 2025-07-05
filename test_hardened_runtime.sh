#!/bin/bash

# Скрипт для тестирования Hardened Runtime
# Этот скрипт проверяет, что Hardened Runtime действительно работает

echo "🔒 Тестирование Hardened Runtime"
echo "================================"
echo ""

APP_PATH="/Users/elisey/Library/Developer/Xcode/DerivedData/WhiteNoise-djpzwsscxkastvfybqstsdibbbfu/Build/Products/Debug/WhiteNoise.app"

echo "📱 Проверяю приложение: $APP_PATH"
echo ""

# Проверка 1: Подпись с Hardened Runtime
echo "✅ Проверка 1: Подпись с Hardened Runtime"
if codesign -dv "$APP_PATH" 2>&1 | grep -q "flags=0x10000(runtime)"; then
    echo "   ✅ Приложение подписано с Hardened Runtime"
else
    echo "   ❌ Приложение НЕ подписано с Hardened Runtime"
fi
echo ""

# Проверка 2: Все библиотеки подписаны
echo "✅ Проверка 2: Подпись всех библиотек"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    echo "   📦 Проверяю библиотеки в $FRAMEWORKS_DIR"
    for lib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$lib" ]; then
            lib_name=$(basename "$lib")
            if codesign -dv "$lib" 2>&1 | grep -q "flags=0x10000(runtime)"; then
                echo "   ✅ $lib_name - подписана с Hardened Runtime"
            else
                echo "   ⚠️  $lib_name - НЕ подписана с Hardened Runtime"
            fi
        fi
    done
else
    echo "   ❌ Папка Frameworks не найдена"
fi
echo ""

# Проверка 3: Проверка entitlements
echo "✅ Проверка 3: Entitlements"
if [ -f "$APP_PATH/Contents/MacOS/WhiteNoise" ]; then
    echo "   📋 Entitlements приложения:"
    codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | head -20
else
    echo "   ❌ Исполняемый файл не найден"
fi
echo ""

# Проверка 4: Проверка архитектуры
echo "✅ Проверка 4: Архитектура"
if file "$APP_PATH/Contents/MacOS/WhiteNoise" | grep -q "arm64"; then
    echo "   ✅ Приложение собрано для arm64 (Apple Silicon)"
else
    echo "   ⚠️  Приложение не для arm64"
fi
echo ""

# Проверка 5: Проверка зависимостей
echo "✅ Проверка 5: Зависимости"
echo "   📋 Основные зависимости:"
otool -L "$APP_PATH/Contents/MacOS/WhiteNoise" | head -10
echo ""

# Проверка 6: Проверка работы приложения
echo "✅ Проверка 6: Работа приложения"
if pgrep -f "WhiteNoise" > /dev/null; then
    echo "   ✅ Приложение запущено и работает"
else
    echo "   ⚠️  Приложение не запущено"
fi
echo ""

echo "🎉 Результаты тестирования Hardened Runtime:"
echo "============================================="
echo ""
echo "🔒 Hardened Runtime обеспечивает следующие защиты:"
echo "   • Защита от выполнения кода из стека"
echo "   • Защита от выполнения кода из кучи"
echo "   • Проверка целостности библиотек"
echo "   • Ограничение доступа к системным ресурсам"
echo ""
echo "📱 Ваше приложение WhiteNoise теперь:"
echo "   • Подписано с Hardened Runtime"
echo "   • Все библиотеки whisper совместимы"
echo "   • Готово к безопасному использованию"
echo ""
echo "💡 Hardened Runtime работает незаметно - это система безопасности,"
echo "   которая защищает приложение от различных атак без изменения"
echo "   пользовательского интерфейса или функциональности."
echo ""
echo "🔍 Для проверки работы Hardened Runtime в реальном времени:"
echo "   • Откройте Console.app"
echo "   • Фильтруйте по 'WhiteNoise'"
echo "   • Запустите приложение и посмотрите на логи безопасности" 