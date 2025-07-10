# Локализация WhiteNoise

Этот документ описывает систему локализации в приложении WhiteNoise.

## Структура локализации

### Файлы локализации

Локализация организована в следующих папках:
- `WhiteNoise/Resources/en.lproj/Localizable.strings` - английский язык
- `WhiteNoise/Resources/ru.lproj/Localizable.strings` - русский язык

### Менеджер локализации

Класс `LocalizationManager` предоставляет удобные методы для работы с локализацией:

```swift
// Получение локализованной строки
let text = "hello_world".localized

// Локализованная строка с параметрами
let text = "welcome_user".localized(with: userName)
```

## Добавление новых языков

### 1. Создание файла локализации

1. Создайте папку `WhiteNoise/Resources/[код_языка].lproj/`
2. Создайте файл `Localizable.strings` в этой папке
3. Скопируйте все ключи из `en.lproj/Localizable.strings`
4. Переведите значения на нужный язык

### 2. Обновление Info.plist

Добавьте код языка в массив `CFBundleLocalizations`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>ru</string>
    <string>es</string> <!-- новый язык -->
</array>
```

### 3. Обновление LocalizationManager

Добавьте новую локаль в массив `supportedLocales`:

```swift
var supportedLocales: [Locale] {
    return [Locale(identifier: "en"), Locale(identifier: "ru"), Locale(identifier: "es")]
}
```

## Добавление новых строк

### 1. Добавление ключа в файлы локализации

Добавьте новый ключ во все файлы локализации:

**en.lproj/Localizable.strings:**
```
"new_feature_title" = "New Feature";
```

**ru.lproj/Localizable.strings:**
```
"new_feature_title" = "Новая функция";
```

### 2. Использование в коде

```swift
Text("new_feature_title".localized)
```

## Форматирование строк

Для строк с параметрами используйте плейсхолдеры:

**en.lproj/Localizable.strings:**
```
"file_size" = "File size: %@";
"progress_percent" = "Progress: %d%%";
```

**ru.lproj/Localizable.strings:**
```
"file_size" = "Размер файла: %@";
"progress_percent" = "Прогресс: %d%%";
```

**Использование в коде:**
```swift
let text = "file_size".localized(with: fileSize)
let progress = "progress_percent".localized(with: percentage)
```

## Лучшие практики

### 1. Именование ключей

- Используйте описательные имена: `download_model_button` вместо `btn1`
- Группируйте ключи по функциональности: `model_*`, `recording_*`, `settings_*`
- Используйте snake_case для ключей

### 2. Комментарии

Добавляйте комментарии в файлы локализации для контекста:

```
// Model selection screen
"model_selection_title" = "Select Model";
"model_download_progress" = "Downloading: %@";
```

### 3. Тестирование

- Тестируйте приложение на всех поддерживаемых языках
- Проверяйте длину текста - некоторые языки могут быть длиннее
- Убедитесь, что все плейсхолдеры корректно заменяются

## Автоматизация

### Генерация файлов локализации

Можно использовать инструменты для автоматического извлечения строк из кода:

```bash
# Пример команды для извлечения строк
genstrings -o WhiteNoise/Resources/en.lproj *.swift
```

### Проверка полноты локализации

Создайте скрипт для проверки, что все ключи присутствуют во всех языках:

```bash
#!/bin/bash
# Проверка полноты локализации
for lang in en ru; do
    echo "Checking $lang..."
    grep -o '"[^"]*"' WhiteNoise/Resources/$lang.lproj/Localizable.strings | sort > /tmp/$lang.keys
done

diff /tmp/en.keys /tmp/ru.keys
```

## Поддерживаемые языки

- **Английский (en)** - основной язык разработки
- **Русский (ru)** - полная поддержка

## Планы на будущее

- Добавление поддержки немецкого языка (de)
- Добавление поддержки французского языка (fr)
- Автоматическая генерация файлов локализации
- Интеграция с системами перевода