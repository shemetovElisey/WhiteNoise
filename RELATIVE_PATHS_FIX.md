# 🔧 Замена жестких путей на относительные

## 📋 Выполненные изменения

### 1. Swift файлы
- **WhisperModel.swift**: Заменены все `URL(fileURLWithPath: "/Users/elisey")` на `FileManager.default.homeDirectoryForCurrentUser`
- **SpeechManager.swift**: Заменен жесткий путь на относительный
- **LocalSpeechRecognizer.swift**: Заменен жесткий путь на относительный

### 2. Entitlements файлы
- **WhiteNoise.entitlements**: Заменен `/Users/elisey/Documents/whisper-models/` на `~/Documents/whisper-models/`

### 3. Bash скрипты
- **fix_built_app_sandbox.sh**: 
  - Заменен `DERIVED_DATA_PATH="/Users/elisey/Library/Developer/Xcode/DerivedData"` на `$HOME/Library/Developer/Xcode/DerivedData`
  - Заменен путь к моделям на относительный
- **prepare_for_app_store.sh**:
  - Заменены пути к DerivedData на `$HOME`
  - Заменен путь к моделям на относительный
- **test_libraries.sh**:
  - Добавлена автоматическая находка приложения вместо жесткого пути
- **test_hardened_runtime.sh**:
  - Добавлена автоматическая находка приложения
- **test_shortcuts.sh**:
  - Добавлена автоматическая находка и запуск приложения
- **fix_adhoc_signing.sh**:
  - Добавлена автоматическая находка приложения
- **fix_app_sandbox_entitlements.sh**:
  - Заменен путь к моделям на относительный

### 4. Документация
- **QUICK_FIX.md**: Заменен жесткий путь на автоматическую находку приложения
- **APP_STORE_SOLUTION.md**: Заменен путь к моделям на относительный

## ✅ Преимущества изменений

1. **Переносимость**: Код теперь работает на любом Mac с любым именем пользователя
2. **Автоматизация**: Скрипты автоматически находят приложение в DerivedData
3. **Универсальность**: Использование `$HOME` вместо жесткого пути `/Users/elisey`
4. **Надежность**: Использование `FileManager.default.homeDirectoryForCurrentUser` в Swift

## 🔍 Проверка

Все жесткие пути `/Users/elisey` были успешно заменены на относительные пути. Проект теперь полностью переносим и будет работать на любом Mac.

## 📝 Примечания

- В Swift используется `FileManager.default.homeDirectoryForCurrentUser` для получения домашней директории
- В bash скриптах используется `$HOME` переменная окружения
- В entitlements используется `~` для относительного пути к домашней директории
- Все скрипты теперь автоматически находят приложение в DerivedData 