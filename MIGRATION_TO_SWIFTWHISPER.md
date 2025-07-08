# Миграция на SwiftWhisper

## Обзор изменений

Проект WhiteNoise был успешно мигрирован на **SwiftWhisper** - современную Swift библиотеку для работы с whisper.cpp.

## Почему SwiftWhisper?

### Преимущества SwiftWhisper:
- ✅ **Простота использования** - "The easiest way to transcribe audio in Swift"
- ✅ **Прямая интеграция с whisper.cpp** - использует проверенную библиотеку
- ✅ **Современный Swift API** - с async/await поддержкой
- ✅ **Поддержка CoreML** - для ускорения на Apple Silicon
- ✅ **Активная разработка** - 704 звезды на GitHub
- ✅ **Простая установка** - через Swift Package Manager
- ✅ **Встроенные делегаты** - для отслеживания прогресса

### Сравнение с WhisperKit:
| Функция | SwiftWhisper | WhisperKit |
|---------|--------------|------------|
| Простота API | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Интеграция с whisper.cpp | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Поддержка CoreML | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Размер библиотеки | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Активность разработки | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## Основные изменения

### 1. Замена библиотек
- **Удалено**: WhisperKitRecognizer
- **Добавлено**: SwiftWhisperRecognizer

### 2. Обновленные файлы
- `SwiftWhisperRecognizer.swift` - новый распознаватель
- `WhisperModel.swift` - возвращены оригинальные .bin файлы
- `SpeechManager.swift` - обновлен для использования SwiftWhisper
- `install_swiftwhisper.sh` - новый скрипт установки

### 3. Структура моделей
SwiftWhisper работает напрямую с .bin файлами whisper.cpp:
```
~/Documents/whisper-models/
├── ggml-tiny.bin
├── ggml-base.bin
├── ggml-small.bin
└── ggml-medium.bin
```

### 4. URL моделей
Возвращены оригинальные URL whisper.cpp:
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
```

## Технические особенности

### API SwiftWhisper
```swift
// Инициализация
let whisper = try Whisper(fromFileURL: modelPath)
whisper.delegate = self

// Транскрипция
let segments = try await whisper.transcribe(audioFrames: audioFrames)
```

### Конвертация аудио
SwiftWhisper требует аудио в формате 16kHz PCM:
```swift
let outputSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: 16000, // SwiftWhisper требует 16kHz
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16
]
```

### Делегаты для отслеживания прогресса
```swift
extension SwiftWhisperRecognizer: WhisperDelegate {
    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        // Обновление прогресса
    }
    
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        // Новые сегменты
    }
}
```

## Инструкции по установке

### Для разработчиков:
1. Клонируйте репозиторий
2. Откройте `WhiteNoise.xcodeproj` в Xcode
3. Добавьте SwiftWhisper как зависимость:
   - Project → Package Dependencies → "+"
   - URL: `https://github.com/exPHAT/SwiftWhisper`
   - Version: Up to Next Major (0.1.0)
4. Добавьте новые файлы в проект:
   - `WhiteNoise/SwiftWhisperRecognizer.swift`
   - `WhiteNoise/install_swiftwhisper.sh`
5. Соберите проект (Cmd+B)

### Для пользователей:
1. Скачайте и установите приложение
2. При первом запуске выберите модель для загрузки
3. Дождитесь завершения загрузки модели
4. Начните использовать распознавание речи

## Совместимость

- **macOS**: 14.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **SwiftWhisper**: 0.1.0+

## Устранение неполадок

### Ошибка загрузки модели
1. Проверьте интернет-соединение
2. Убедитесь, что у приложения есть доступ к сети
3. Попробуйте другую модель

### Ошибка инициализации SwiftWhisper
1. Проверьте, что модель полностью загружена
2. Перезапустите приложение
3. Удалите и переустановите модель

### Проблемы с конвертацией аудио
1. Убедитесь, что аудиофайл не поврежден
2. Проверьте формат аудио (поддерживаются WAV, MP3, M4A)
3. Перезапустите приложение

## Преимущества миграции

### Производительность
- ✅ Прямая интеграция с whisper.cpp
- ✅ Оптимизация для Apple Silicon через CoreML
- ✅ Эффективная обработка аудио

### Разработка
- ✅ Простой и понятный API
- ✅ Современный Swift с async/await
- ✅ Встроенная поддержка прогресса

### Пользовательский опыт
- ✅ Быстрая инициализация
- ✅ Отслеживание прогресса транскрипции
- ✅ Стабильная работа

## Обратная совместимость

- ✅ Поддержка существующих .bin моделей
- ✅ Совместимость с whisper.cpp моделями
- ✅ Простая миграция с предыдущих версий

## Контакты

При возникновении проблем создайте issue в репозитории или обратитесь к документации SwiftWhisper: https://github.com/exPHAT/SwiftWhisper 