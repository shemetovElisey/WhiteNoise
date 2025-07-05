# Установка Whisper.cpp для локального распознавания речи

Для использования локального распознавания речи необходимо установить Whisper.cpp.

## Автоматическая установка

1. Откройте Terminal
2. Перейдите в папку проекта
3. Выполните команду:

```bash
chmod +x WhiteNoise/install_whisper.sh
./WhiteNoise/install_whisper.sh
```

## Ручная установка

### 1. Установка Homebrew (если не установлен)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Установка Whisper.cpp

```bash
brew install whisper-cpp
```

### 3. Создание директории для моделей

```bash
mkdir -p ~/Documents/whisper-models
cd ~/Documents/whisper-models
```

### 4. Загрузка модели

```bash
curl -L -O "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
```

## Проверка установки

Выполните команду для проверки:

```bash
whisper --help
```

Если команда выполняется без ошибок, установка прошла успешно.

## Доступные модели

- **tiny** (39 MB) - самая быстрая, подходит для большинства задач
- **base** (142 MB) - лучшее качество, медленнее
- **small** (466 MB) - еще лучше качество
- **medium** (1.5 GB) - высокое качество
- **large** (3.1 GB) - максимальное качество

Для загрузки других моделей замените `ggml-tiny.bin` на нужную модель:

```bash
curl -L -O "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
```

## Настройка в приложении

1. Запустите приложение
2. Откройте настройки
3. Выберите "Локальная модель" в режиме распознавания
4. Сохраните настройки

## Устранение неполадок

### Ошибка "command not found: whisper"

Убедитесь, что Whisper.cpp установлен:
```bash
brew list | grep whisper
```

### Ошибка "model not found"

Проверьте, что модель загружена:
```bash
ls ~/Documents/whisper-models/
```

### Медленная работа

- Используйте модель `tiny` для максимальной скорости
- Закройте другие приложения для освобождения ресурсов
- Убедитесь, что у вас достаточно оперативной памяти (минимум 4 GB)

## Производительность

Примерное время обработки на MacBook Air M1:
- **tiny**: 1-3 секунды
- **base**: 3-8 секунд
- **small**: 8-15 секунд
- **medium**: 15-30 секунд
- **large**: 30-60 секунд

Время зависит от длины аудио и производительности компьютера. 