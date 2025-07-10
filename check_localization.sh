#!/bin/bash

# Скрипт для проверки полноты локализации в WhiteNoise
# Проверяет, что все ключи присутствуют во всех языках

set -e

echo "🔍 Проверка полноты локализации WhiteNoise..."
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для извлечения ключей из файла
extract_keys() {
    local file="$1"
    if [ -f "$file" ]; then
        # Извлекаем только ключи (строки вида "key" = "value";)
        grep '^[[:space:]]*"[^"]*"[[:space:]]*=' "$file" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/' | sort
    else
        echo "Файл не найден: $file" >&2
        return 1
    fi
}

# Проверяем наличие файлов локализации
EN_FILE="WhiteNoise/Resources/en.lproj/Localizable.strings"
RU_FILE="WhiteNoise/Resources/ru.lproj/Localizable.strings"

if [ ! -f "$EN_FILE" ]; then
    echo -e "${RED}❌ Файл английской локализации не найден: $EN_FILE${NC}"
    exit 1
fi

if [ ! -f "$RU_FILE" ]; then
    echo -e "${RED}❌ Файл русской локализации не найден: $RU_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Файлы локализации найдены${NC}"
echo ""

# Извлекаем ключи
echo "📝 Извлечение ключей..."
EN_KEYS=$(extract_keys "$EN_FILE")
RU_KEYS=$(extract_keys "$RU_FILE")

# Подсчитываем количество ключей
EN_COUNT=$(echo "$EN_KEYS" | wc -l)
RU_COUNT=$(echo "$RU_KEYS" | wc -l)

echo -e "${GREEN}📊 Статистика:${NC}"
echo "  Английский: $EN_COUNT ключей"
echo "  Русский: $RU_COUNT ключей"
echo ""

# Проверяем различия
echo "🔍 Проверка различий..."

# Ключи, которые есть в английском, но нет в русском
MISSING_IN_RU=$(comm -23 <(echo "$EN_KEYS") <(echo "$RU_KEYS"))

# Ключи, которые есть в русском, но нет в английском
MISSING_IN_EN=$(comm -13 <(echo "$EN_KEYS") <(echo "$RU_KEYS"))

# Общие ключи
COMMON_KEYS=$(comm -12 <(echo "$EN_KEYS") <(echo "$RU_KEYS"))
COMMON_COUNT=$(echo "$COMMON_KEYS" | wc -l)

echo -e "${GREEN}✅ Общих ключей: $COMMON_COUNT${NC}"

# Выводим результаты
if [ -n "$MISSING_IN_RU" ]; then
    echo -e "${RED}❌ Ключи, отсутствующие в русской локализации:${NC}"
    echo "$MISSING_IN_RU" | sed 's/^/  - /'
    echo ""
fi

if [ -n "$MISSING_IN_EN" ]; then
    echo -e "${YELLOW}⚠️  Ключи, отсутствующие в английской локализации:${NC}"
    echo "$MISSING_IN_EN" | sed 's/^/  - /'
    echo ""
fi

# Проверяем пустые значения
echo "🔍 Проверка пустых значений..."

EMPTY_EN=$(grep '= "";' "$EN_FILE" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
EMPTY_RU=$(grep '= "";' "$RU_FILE" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')

if [ -n "$EMPTY_EN" ]; then
    echo -e "${YELLOW}⚠️  Пустые значения в английской локализации:${NC}"
    echo "$EMPTY_EN" | sed 's/^/  - /'
    echo ""
fi

if [ -n "$EMPTY_RU" ]; then
    echo -e "${YELLOW}⚠️  Пустые значения в русской локализации:${NC}"
    echo "$EMPTY_RU" | sed 's/^/  - /'
    echo ""
fi

# Итоговый результат
if [ -z "$MISSING_IN_RU" ] && [ -z "$MISSING_IN_EN" ] && [ -z "$EMPTY_EN" ] && [ -z "$EMPTY_RU" ]; then
    echo -e "${GREEN}🎉 Локализация полностью синхронизирована!${NC}"
    exit 0
else
    echo -e "${RED}❌ Обнаружены проблемы с локализацией${NC}"
    exit 1
fi