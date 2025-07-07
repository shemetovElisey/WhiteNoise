#!/bin/bash

# Скрипт для загрузки моделей Whisper
# Автоматически загружает и устанавливает различные модели Whisper

set -e

echo "🎯 Загрузка моделей Whisper"
echo "=========================="

# Создаем директорию для моделей
MODELS_DIR="$HOME/Documents/whisper-models"
mkdir -p "$MODELS_DIR"

echo "📁 Директория моделей: $MODELS_DIR"

# Список доступных моделей
declare -A MODELS=(
    ["ggml-tiny.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
    ["ggml-base.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    ["ggml-small.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
    ["ggml-medium.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
    ["ggml-large.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin"
    ["ggml-large-v2.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin"
    ["ggml-large-v3.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin"
)

# Размеры моделей (в байтах)
declare -A SIZES=(
    ["ggml-tiny.bin"]="40960000"
    ["ggml-base.bin"]="77600000"
    ["ggml-small.bin"]="256000000"
    ["ggml-medium.bin"]="806000000"
    ["ggml-large.bin"]="1625000000"
    ["ggml-large-v2.bin"]="1625000000"
    ["ggml-large-v3.bin"]="1625000000"
)

# Функция для форматирования размера
format_size() {
    local bytes=$1
    if [ $bytes -gt 1073741824 ]; then
        echo "$(echo "scale=1; $bytes/1073741824" | bc) GB"
    elif [ $bytes -gt 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc) MB"
    else
        echo "$(echo "scale=1; $bytes/1024" | bc) KB"
    fi
}

# Функция для загрузки модели
download_model() {
    local model_name=$1
    local url=$2
    local model_path="$MODELS_DIR/$model_name"
    local expected_size=${SIZES[$model_name]}
    
    echo ""
    echo "📥 Загружаем $model_name..."
    echo "   URL: $url"
    echo "   Размер: $(format_size $expected_size)"
    
    # Проверяем, существует ли уже файл
    if [ -f "$model_path" ]; then
        local actual_size=$(stat -f%z "$model_path" 2>/dev/null || stat -c%s "$model_path" 2>/dev/null)
        if [ "$actual_size" = "$expected_size" ]; then
            echo "   ✅ Модель уже загружена и корректна"
            return 0
        else
            echo "   ⚠️  Файл существует, но размер не совпадает. Перезагружаем..."
            rm -f "$model_path"
        fi
    fi
    
    # Загружаем файл
    if curl -L -o "$model_path" "$url"; then
        local actual_size=$(stat -f%z "$model_path" 2>/dev/null || stat -c%s "$model_path" 2>/dev/null)
        if [ "$actual_size" = "$expected_size" ]; then
            echo "   ✅ Модель успешно загружена"
            return 0
        else
            echo "   ❌ Ошибка: размер файла не совпадает"
            echo "      Ожидалось: $expected_size байт"
            echo "      Получено: $actual_size байт"
            rm -f "$model_path"
            return 1
        fi
    else
        echo "   ❌ Ошибка загрузки"
        rm -f "$model_path"
        return 1
    fi
}

# Проверяем аргументы
if [ $# -eq 0 ]; then
    echo "Использование: $0 [tiny|base|small|medium|large|large-v2|large-v3|all]"
    echo ""
    echo "Доступные модели:"
    echo "  tiny      - 39 MB, очень быстро, хорошая точность"
    echo "  base      - 74 MB, быстро, лучшая точность"
    echo "  small     - 244 MB, средне, отличная точность"
    echo "  medium    - 769 MB, медленно, превосходная точность"
    echo "  large     - 1550 MB, очень медленно, максимальная точность"
    echo "  large-v2  - 1550 MB, улучшенная версия large"
    echo "  large-v3  - 1550 MB, последняя версия large"
    echo "  all       - загрузить все модели"
    echo ""
    echo "Примеры:"
    echo "  $0 tiny          # Загрузить только tiny модель"
    echo "  $0 base small    # Загрузить base и small модели"
    echo "  $0 all           # Загрузить все модели"
    exit 1
fi

# Обрабатываем аргументы
models_to_download=()
for arg in "$@"; do
    case $arg in
        "tiny")
            models_to_download+=("ggml-tiny.bin")
            ;;
        "base")
            models_to_download+=("ggml-base.bin")
            ;;
        "small")
            models_to_download+=("ggml-small.bin")
            ;;
        "medium")
            models_to_download+=("ggml-medium.bin")
            ;;
        "large")
            models_to_download+=("ggml-large.bin")
            ;;
        "large-v2")
            models_to_download+=("ggml-large-v2.bin")
            ;;
        "large-v3")
            models_to_download+=("ggml-large-v3.bin")
            ;;
        "all")
            models_to_download=("${!MODELS[@]}")
            ;;
        *)
            echo "❌ Неизвестная модель: $arg"
            exit 1
            ;;
    esac
done

# Загружаем выбранные модели
echo ""
echo "🎯 Загружаем ${#models_to_download[@]} модель(ей)..."
echo ""

success_count=0
total_count=${#models_to_download[@]}

for model in "${models_to_download[@]}"; do
    if download_model "$model" "${MODELS[$model]}"; then
        ((success_count++))
    fi
done

echo ""
echo "📊 Результат загрузки:"
echo "   ✅ Успешно: $success_count/$total_count"
echo "   ❌ Ошибок: $((total_count - success_count))"

if [ $success_count -eq $total_count ]; then
    echo ""
    echo "🎉 Все модели успешно загружены!"
    echo ""
    echo "📋 Следующие шаги:"
    echo "   1. Запустите приложение WhiteNoise"
    echo "   2. Откройте настройки (Cmd+,)"
    echo "   3. Выберите нужную модель"
    echo "   4. Начните использовать голосовой ввод (Cmd+Shift+V)"
else
    echo ""
    echo "⚠️  Некоторые модели не удалось загрузить."
    echo "   Попробуйте запустить скрипт еще раз или загрузить модели по отдельности."
fi

echo ""
echo "📁 Модели сохранены в: $MODELS_DIR" 