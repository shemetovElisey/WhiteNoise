#!/bin/bash

# Основной скрипт для настройки Hardened Runtime для Whisper
# Этот скрипт выполняет все необходимые шаги для совместимости с Hardened Runtime

set -e

echo "🔒 Настройка Hardened Runtime для Whisper"
echo "=========================================="
echo ""

# Проверяем, что мы на macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Ошибка: этот скрипт предназначен только для macOS"
    exit 1
fi

# Проверяем, что мы в правильной директории
if [ ! -d "whisper.cpp" ] || [ ! -f "WhiteNoise.xcodeproj/project.pbxproj" ]; then
    echo "❌ Ошибка: не найдены необходимые файлы проекта"
    echo "💡 Убедитесь, что вы находитесь в корневой папке проекта WhiteNoise"
    exit 1
fi

echo "📋 Выполняю следующие шаги:"
echo "   1. Сборка библиотек whisper с поддержкой Hardened Runtime"
echo "   2. Настройка параметров безопасности в проекте Xcode"
echo "   3. Подпись библиотек для совместимости"
echo "   4. Проверка совместимости"
echo ""

# Шаг 1: Сборка библиотек с поддержкой Hardened Runtime
echo "🚀 Шаг 1: Сборка библиотек whisper с поддержкой Hardened Runtime"
echo "---------------------------------------------------------------"
./build_whisper_libs.sh

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при сборке библиотек"
    exit 1
fi

echo ""
echo "✅ Шаг 1 завершен успешно!"
echo ""

# Шаг 2: Настройка параметров безопасности в проекте
echo "🔒 Шаг 2: Настройка параметров безопасности в проекте Xcode"
echo "------------------------------------------------------------"
./setup_hardened_runtime.sh

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при настройке параметров безопасности"
    exit 1
fi

echo ""
echo "✅ Шаг 2 завершен успешно!"
echo ""

# Шаг 3: Подпись библиотек
echo "🔐 Шаг 3: Подпись библиотек для совместимости"
echo "----------------------------------------------"
./sign_libraries.sh

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при подписи библиотек"
    exit 1
fi

echo ""
echo "✅ Шаг 3 завершен успешно!"
echo ""

# Шаг 4: Финальная проверка
echo "🔍 Шаг 4: Финальная проверка совместимости"
echo "-------------------------------------------"

echo "📱 Проверяю настройки проекта..."
if grep -q "ENABLE_HARDENED_RUNTIME.*YES" WhiteNoise.xcodeproj/project.pbxproj; then
    echo "   ✅ Hardened Runtime включен в проекте"
else
    echo "   ⚠️  Hardened Runtime не найден в проекте (настройте вручную в Xcode)"
fi

echo ""
echo "📦 Проверяю наличие библиотек..."
RESOURCES_DIR="WhiteNoise/Resources"
if [ -d "$RESOURCES_DIR" ]; then
    library_count=$(ls "$RESOURCES_DIR"/*.dylib 2>/dev/null | wc -l)
    echo "   ✅ Найдено $library_count библиотек в $RESOURCES_DIR"
else
    echo "   ❌ Папка Resources не найдена"
fi

echo ""
echo "🎉 Настройка Hardened Runtime завершена!"
echo "=========================================="
echo ""
echo "📋 Следующие шаги для завершения настройки:"
echo ""
echo "1. Откройте проект в Xcode:"
echo "   open WhiteNoise.xcodeproj"
echo ""
echo "2. В Xcode настройте Hardened Runtime:"
echo "   - Выберите target WhiteNoise"
echo "   - Перейдите в Signing & Capabilities"
echo "   - Включите Hardened Runtime"
echo "   - При необходимости добавьте исключения для библиотек"
echo ""
echo "3. Соберите и запустите приложение:"
echo "   - Выберите целевое устройство"
echo "   - Нажмите Cmd+R для сборки и запуска"
echo ""
echo "🔒 Hardened Runtime обеспечивает:"
echo "   - Защиту от выполнения кода из стека"
echo "   - Защиту от выполнения кода из кучи"
echo "   - Проверку целостности библиотек"
echo "   - Ограничение доступа к системным ресурсам"
echo ""
echo "⚠️  Если возникнут проблемы:"
echo "   - Проверьте, что все библиотеки подписаны"
echo "   - Добавьте библиотеки в исключения Hardened Runtime"
echo "   - Убедитесь, что приложение подписано с Hardened Runtime"
echo ""
echo "📞 Для получения помощи:"
echo "   - Проверьте логи Xcode"
echo "   - Используйте команду: codesign -dv /path/to/app"
echo "   - Проверьте настройки безопасности в System Preferences" 