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

# Инструкция по установке WhiteNoise

## 🚀 Быстрый старт (рекомендуется)

### Для пользователей

1. **Скачайте проект:**
   ```bash
   git clone <your-repo-url>
   cd WhiteNoise
   ```

2. **Запустите автоматическую установку:**
   ```bash
   ./build_whisper_libs.sh
   ```

3. **Откройте проект в Xcode:**
   ```bash
   open WhiteNoise.xcodeproj
   ```

4. **Соберите и запустите:**
   - Выберите устройство (iPhone/Simulator)
   - Нажмите `Cmd+R`

**Готово!** Приложение работает из коробки.

## 🔧 Ручная установка

### Требования

- macOS 12.0 или новее
- Xcode 14.0 или новее
- Git
- CMake (устанавливается автоматически с Xcode)

### Пошаговая установка

#### 1. Подготовка окружения

```bash
# Проверяем наличие Xcode
xcode-select --install

# Проверяем CMake
cmake --version
```

#### 2. Клонирование whisper.cpp

```bash
# Если whisper.cpp еще не клонирован
git clone https://github.com/ggerganov/whisper.cpp.git
```

#### 3. Сборка библиотек

```bash
cd whisper.cpp

# Создаем build директорию
mkdir -p build
cd build

# Конфигурируем CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# Собираем
cmake --build . --config Release
```

#### 4. Копирование в проект

```bash
# Возвращаемся в корневую папку
cd ../..

# Копируем библиотеки
./add_resources_to_xcode.sh
```

#### 5. Открытие в Xcode

```bash
open WhiteNoise.xcodeproj
```

## 📱 Настройка в Xcode

### Добавление ресурсов

1. Откройте `WhiteNoise.xcodeproj`
2. В навигаторе проекта найдите папку `WhiteNoise`
3. Правый клик → "Add Files to 'WhiteNoise'"
4. Выберите папку `WhiteNoise/Resources`
5. Убедитесь, что выбрано "Add to target: WhiteNoise"
6. Нажмите "Add"

### Настройка линковки

1. Выберите проект в навигаторе
2. Выберите target "WhiteNoise"
3. Перейдите в "Build Settings"
4. Найдите "Library Search Paths"
5. Добавьте: `$(SRCROOT)/WhiteNoise/Resources`

### Настройка заголовочных файлов

1. В "Build Settings" найдите "Header Search Paths"
2. Добавьте: `$(SRCROOT)/WhiteNoise/Resources`

## 🐛 Устранение проблем

### Ошибка "library not found"

```bash
# Пересоберите библиотеки
./build_whisper_libs.sh
```

### Ошибка "permission denied"

```bash
# Сделайте скрипты исполняемыми
chmod +x build_whisper_libs.sh
chmod +x add_resources_to_xcode.sh
```

### Ошибка CMake

```bash
# Установите CMake через Homebrew
brew install cmake

# Или обновите Xcode Command Line Tools
xcode-select --install
```

### Ошибка компиляции

1. Очистите проект: `Cmd+Shift+K`
2. Очистите папку DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Пересоберите: `Cmd+B`

### Проблемы с архитектурой

Убедитесь, что собираете для правильной архитектуры:

```bash
# Для Apple Silicon (M1/M2)
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64

# Для Intel
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=x86_64

# Универсальная сборка
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

## 📦 Структура файлов

После установки структура должна выглядеть так:

```
WhiteNoise/
├── WhiteNoise.xcodeproj/
├── WhiteNoise/
│   ├── Resources/
│   │   ├── libwhisper.dylib
│   │   ├── libwhisper.1.dylib
│   │   ├── libwhisper.1.7.6.dylib
│   │   ├── libggml.dylib
│   │   ├── libggml-base.dylib
│   │   ├── libggml-cpu.dylib
│   │   ├── libggml-metal.dylib
│   │   ├── libggml-blas.dylib
│   │   └── whisper.h
│   └── *.swift
├── whisper.cpp/
│   └── build/
├── build_whisper_libs.sh
├── add_resources_to_xcode.sh
└── README.md
```

## 🔄 Обновление

Для обновления библиотек whisper:

```bash
# Обновите whisper.cpp
cd whisper.cpp
git pull

# Пересоберите библиотеки
cd ..
./build_whisper_libs.sh
```

## 📞 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи сборки в Xcode
2. Убедитесь, что все зависимости установлены
3. Попробуйте очистить и пересобрать проект
4. Создайте Issue в GitHub с подробным описанием проблемы

---

**Удачной установки! 🎉** 