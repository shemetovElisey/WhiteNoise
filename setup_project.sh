#!/bin/bash

# Главный скрипт настройки проекта WhiteNoise
# Запускайте этот скрипт один раз при первом клонировании проекта

set -e

echo "🎉 Добро пожаловать в WhiteNoise!"
echo "🚀 Начинаю автоматическую настройку проекта..."

# Проверяем, что мы в правильной директории
if [ ! -f "WhiteNoise.xcodeproj/project.pbxproj" ]; then
    echo "❌ Ошибка: проект WhiteNoise.xcodeproj не найден"
    echo "💡 Убедитесь, что вы находитесь в корневой папке проекта WhiteNoise"
    exit 1
fi

echo "✅ Проект найден"

# Проверяем наличие whisper.cpp
if [ ! -d "whisper.cpp" ]; then
    echo "📦 Клонирую whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    echo "✅ whisper.cpp клонирован"
else
    echo "✅ whisper.cpp уже существует"
fi

# Делаем скрипты исполняемыми
echo "🔧 Настраиваю скрипты..."
chmod +x build_whisper_libs.sh
chmod +x add_resources_to_xcode.sh
chmod +x WhiteNoise/install_whisper.sh

# Собираем библиотеки
echo "🔨 Собираю библиотеки whisper..."
./build_whisper_libs.sh

echo ""
echo "🎉 Настройка завершена успешно!"
echo ""
echo "📱 Следующие шаги:"
echo "   1. Откройте проект в Xcode:"
echo "      open WhiteNoise.xcodeproj"
echo ""
echo "   2. Убедитесь, что папка Resources добавлена в проект:"
echo "      - В навигаторе проекта найдите WhiteNoise"
echo "      - Правый клик → Add Files to 'WhiteNoise'"
echo "      - Выберите папку WhiteNoise/Resources"
echo "      - Убедитесь, что выбрано 'Add to target: WhiteNoise'"
echo ""
echo "   3. Соберите и запустите приложение:"
echo "      - Выберите устройство (iPhone/Simulator)"
echo "      - Нажмите Cmd+R"
echo ""
echo "💡 Приложение готово к работе из коробки!"
echo "   Все библиотеки whisper уже включены в проект."
echo ""
echo "📚 Дополнительная информация:"
echo "   - README.md - общая информация о проекте"
echo "   - INSTALL_WHISPER.md - подробные инструкции по установке" 