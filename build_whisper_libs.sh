#!/bin/bash

# Скрипт для автоматической сборки библиотек whisper с поддержкой Hardened Runtime
# Этот скрипт собирает whisper.cpp и копирует библиотеки в проект

set -e

echo "🚀 Начинаю сборку библиотек whisper с поддержкой Hardened Runtime..."

# Проверяем, что мы в правильной директории
if [ ! -d "whisper.cpp" ]; then
    echo "❌ Ошибка: папка whisper.cpp не найдена"
    echo "💡 Убедитесь, что вы находитесь в корневой папке проекта"
    exit 1
fi

# Проверяем, что мы на macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Ошибка: этот скрипт предназначен только для macOS"
    exit 1
fi

# Переходим в папку whisper.cpp
cd whisper.cpp

echo "📦 Собираю whisper.cpp с поддержкой Hardened Runtime..."

# Очищаем предыдущую сборку
if [ -d "build" ]; then
    echo "🧹 Очищаю предыдущую сборку..."
    rm -rf build
fi

# Настраиваем флаги для Hardened Runtime
export CMAKE_ARGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_C_FLAGS='-fPIC -fstack-protector-strong'"
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_CXX_FLAGS='-fPIC -fstack-protector-strong'"
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_EXE_LINKER_FLAGS='-Wl,-headerpad_max_install_names'"
export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_SHARED_LINKER_FLAGS='-Wl,-headerpad_max_install_names'"

# Собираем библиотеки
echo "🔨 Запускаю сборку с флагами: $CMAKE_ARGS"
make build

if [ $? -eq 0 ]; then
    echo "✅ Сборка whisper.cpp завершена успешно!"
else
    echo "❌ Ошибка при сборке whisper.cpp"
    exit 1
fi

# Возвращаемся в корневую папку
cd ..

# Копируем библиотеки в проект
echo "📋 Копирую библиотеки в проект..."
./add_resources_to_xcode.sh

echo ""
echo "🎉 Все готово! Библиотеки whisper успешно собраны с поддержкой Hardened Runtime."
echo "📱 Теперь можно открыть проект в Xcode и собрать приложение."
echo ""
echo "💡 Для сборки приложения:"
echo "   1. Откройте WhiteNoise.xcodeproj в Xcode"
echo "   2. Выберите целевое устройство (iPhone или Simulator)"
echo "   3. Убедитесь, что в настройках проекта включен Hardened Runtime"
echo "   4. Нажмите Cmd+R для сборки и запуска"
echo ""
echo "🔒 Hardened Runtime включен для повышения безопасности приложения" 