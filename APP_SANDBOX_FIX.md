# Исправление App Sandbox для App Store

## Проблема

При попытке загрузить приложение в App Store Connect возникает ошибка валидации:

```
Validation failed
App sandbox not enabled. The following executables must include the "com.apple.security.app-sandbox" entitlement with a Boolean value of true in the entitlements property list: [( "io.melxyty.WhiteNoise.pkg/Payload/WhiteNoise.app/Contents/Resources/whisper-cli" )]
```

## Причина

Исполняемый файл `whisper-cli` в папке `Contents/Resources` приложения не имеет необходимого entitlement `com.apple.security.app-sandbox` со значением `true`. Это требование App Store для всех исполняемых файлов в приложении.

## Решение

### 1. Исправление исходных файлов

Для исправления файлов в исходном проекте:

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_app_sandbox_entitlements.sh
```

Этот скрипт:
- Добавляет App Sandbox entitlement к `whisper-cli`
- Переподписывает все библиотеки для совместимости
- Проверяет корректность применения entitlements

### 2. Исправление собранного приложения

После сборки приложения в Xcode, для исправления файлов в DerivedData:

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_built_app_sandbox.sh
```

Или с указанием конкретного пути:

```bash
SIGN_IDENTITY="Apple Development: e.shemetov.o@gmail.com (HHNUQBXJ93)" ./fix_built_app_sandbox.sh /path/to/WhiteNoise.app
```

### 3. Проверка результата

Убедитесь, что entitlement применен корректно:

```bash
codesign -d --entitlements :- WhiteNoise/Resources/whisper-cli
```

Должен показать:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

## Entitlements для whisper-cli

Скрипт добавляет следующие entitlements к `whisper-cli`:

- `com.apple.security.app-sandbox` = `true` (обязательно для App Store)
- `com.apple.security.network.client` = `true` (для сетевых запросов)
- `com.apple.security.files.user-selected.read-write` = `true` (для работы с файлами)
- `com.apple.security.files.downloads.read-write` = `true` (для работы с Downloads)
- `com.apple.security.temporary-exception.files.absolute-path.read-write` (для папки с моделями)

## Процесс публикации

1. **Соберите приложение** в Xcode (Product → Archive)
2. **Запустите скрипт исправления** для собранного приложения
3. **Загрузите в App Store Connect** через Xcode или Application Loader
4. **Проверьте валидацию** - ошибка App Sandbox должна исчезнуть

## Важные моменты

- **Hardened Runtime** должен быть включен в настройках проекта
- **App Sandbox** должен быть включен в основных entitlements приложения
- Все исполняемые файлы в приложении должны иметь App Sandbox entitlement
- Библиотеки (.dylib) не требуют App Sandbox entitlement

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

Это обеспечит автоматическое применение App Sandbox entitlements при каждой сборке Release версии.

## Устранение неполадок

### Ошибка "codesign failed"

Убедитесь, что:
- Сертификат подписи действителен
- У вас есть права на подпись
- Hardened Runtime включен

### Ошибка "entitlement not found"

Проверьте, что скрипт выполнился успешно и entitlement был применен:

```bash
codesign -d --entitlements :- /path/to/whisper-cli
```

### Повторяющаяся ошибка валидации

Убедитесь, что:
- Скрипт применен к правильной версии приложения
- Все файлы переподписаны
- Основное приложение также переподписано с флагом `--deep` 