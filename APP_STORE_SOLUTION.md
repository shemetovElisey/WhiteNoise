# Решение проблемы App Sandbox для App Store

## Проблема

При попытке загрузить приложение в App Store Connect возникает ошибка валидации:

```
Validation failed
App sandbox not enabled. The following executables must include the "com.apple.security.app-sandbox" entitlement with a Boolean value of true in the entitlements property list: [( "io.melxyty.WhiteNoise.pkg/Payload/WhiteNoise.app/Contents/Resources/whisper-cli" )]
```

## Причина

Исполняемый файл `whisper-cli` в папке `Contents/Resources` приложения не имеет необходимого entitlement `com.apple.security.app-sandbox` со значением `true`. Это обязательное требование App Store для всех исполняемых файлов в приложении.

## Решение

### Автоматическое решение (рекомендуется)

Используйте автоматический скрипт для подготовки к App Store:

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./prepare_for_app_store.sh
```

Этот скрипт автоматически:
1. Очищает предыдущие сборки
2. Собирает Release версию
3. Находит собранное приложение
4. Применяет App Sandbox entitlements к `whisper-cli`
5. Переподписывает приложение
6. Проверяет валидацию
7. Создает архив для App Store

### Ручное решение

Если автоматический скрипт не работает, выполните следующие шаги:

#### Шаг 1: Исправление исходных файлов

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_app_sandbox_entitlements.sh
```

#### Шаг 2: Сборка Release версии

```bash
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build
```

#### Шаг 3: Исправление собранного приложения

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_built_app_sandbox.sh
```

#### Шаг 4: Проверка результата

```bash
codesign -d --entitlements :- /path/to/WhiteNoise.app/Contents/Resources/whisper-cli
```

Должен показать:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

## Что было исправлено

### 1. Добавление whisper-cli в проект

В файле `WhiteNoise.xcodeproj/project.pbxproj` добавлен `whisper-cli` в список копируемых файлов:

```diff
membershipExceptions = (
    "Resources/libggml-base.dylib",
    "Resources/libggml-blas.dylib",
    "Resources/libggml-cpu.dylib",
    "Resources/libggml-metal.dylib",
    Resources/libggml.dylib,
    Resources/libwhisper.1.7.6.dylib,
    Resources/libwhisper.1.dylib,
    Resources/libwhisper.dylib,
+   "Resources/whisper-cli",
);
```

### 2. App Sandbox Entitlements для whisper-cli

Создан специальный файл entitlements для `whisper-cli`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <array>
        <string>~/Documents/whisper-models/</string>
    </array>
</dict>
</plist>
```

### 3. Переподпись с правильными entitlements

Скрипт переподписывает `whisper-cli` с новыми entitlements:

```bash
codesign --force --sign "$SIGN_IDENTITY" --entitlements "$entitlements_file" --options runtime "$whisper_cli_path"
```

## Структура файлов в приложении

После исправления структура файлов выглядит так:

```
WhiteNoise.app/
├── Contents/
│   ├── Frameworks/
│   │   ├── libwhisper.dylib (подписана)
│   │   ├── libggml.dylib (подписана)
│   │   ├── whisper-cli (подписана)
│   │   └── ... (другие библиотеки)
│   ├── Resources/
│   │   ├── whisper-cli (подписана с App Sandbox)
│   │   ├── AppIcon.icns
│   │   └── Assets.car
│   └── MacOS/
│       └── WhiteNoise (основное приложение)
```

## Entitlements для whisper-cli

- `com.apple.security.app-sandbox` = `true` (обязательно для App Store)
- `com.apple.security.network.client` = `true` (для сетевых запросов)
- `com.apple.security.files.user-selected.read-write` = `true` (для работы с файлами)
- `com.apple.security.files.downloads.read-write` = `true` (для работы с Downloads)
- `com.apple.security.temporary-exception.files.absolute-path.read-write` (для папки с моделями)

## Процесс публикации

1. **Запустите автоматический скрипт**:
   ```bash
   SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./prepare_for_app_store.sh
   ```

2. **Откройте Xcode** и выберите Product → Archive

3. **В Organizer** выберите ваше приложение и нажмите "Distribute App"

4. **Выберите "App Store Connect"** и следуйте инструкциям

5. **Загрузите в App Store Connect** - ошибка App Sandbox должна исчезнуть

## Проверка результата

### Проверка entitlements

```bash
codesign -d --entitlements :- /path/to/WhiteNoise.app/Contents/Resources/whisper-cli
```

### Проверка валидации

```bash
codesign --verify --verbose=4 /path/to/WhiteNoise.app
```

### Проверка структуры

```bash
ls -la /path/to/WhiteNoise.app/Contents/Resources/
ls -la /path/to/WhiteNoise.app/Contents/Frameworks/
```

## Устранение неполадок

### Ошибка "codesign failed"

Убедитесь, что:
- Сертификат подписи действителен
- У вас есть права на подпись
- Hardened Runtime включен в настройках проекта

### Ошибка "entitlement not found"

Проверьте, что скрипт выполнился успешно:
```bash
codesign -d --entitlements :- /path/to/whisper-cli
```

### Повторяющаяся ошибка валидации

Убедитесь, что:
- Скрипт применен к правильной версии приложения
- Все файлы переподписаны
- Основное приложение также переподписано с флагом `--deep`

### whisper-cli не копируется

Проверьте настройки проекта в Xcode:
1. Выберите target WhiteNoise
2. Перейдите в Build Phases
3. Убедитесь, что `whisper-cli` добавлен в Copy Files phase

## Автоматизация

Для автоматизации процесса можно добавить скрипт в Build Phases в Xcode:

1. Откройте настройки проекта
2. Выберите target WhiteNoise
3. Перейдите в Build Phases
4. Добавьте New Run Script Phase
5. Добавьте команду:

```bash
if [ "$CONFIGURATION" = "Release" ]; then
    SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_app_sandbox_entitlements.sh
fi
```

## Важные моменты

- **Hardened Runtime** должен быть включен в настройках проекта
- **App Sandbox** должен быть включен в основных entitlements приложения
- Все исполняемые файлы в приложении должны иметь App Sandbox entitlement
- Библиотеки (.dylib) не требуют App Sandbox entitlement
- Используйте Release конфигурацию для App Store

## Результат

После применения всех исправлений:
- ✅ `whisper-cli` имеет App Sandbox entitlement
- ✅ Приложение проходит валидацию codesign
- ✅ Приложение готово для загрузки в App Store Connect
- ✅ Ошибка App Sandbox больше не возникает 