# Настройка Hardened Runtime для Whisper

Этот документ описывает процесс настройки Hardened Runtime для приложения WhiteNoise с библиотеками Whisper.

## Что такое Hardened Runtime?

Hardened Runtime - это система безопасности macOS, которая обеспечивает:

- **Защиту от выполнения кода из стека** - предотвращает атаки типа buffer overflow
- **Защиту от выполнения кода из кучи** - блокирует выполнение кода в динамически выделенной памяти
- **Проверку целостности библиотек** - гарантирует, что загружаемые библиотеки не были изменены
- **Ограничение доступа к системным ресурсам** - контролирует доступ к файловой системе, сети и другим ресурсам

## Автоматическая настройка

Для автоматической настройки Hardened Runtime выполните:

```bash
./setup_whisper_hardened_runtime.sh
```

Этот скрипт выполнит все необходимые шаги:

1. **Сборка библиотек** с поддержкой Hardened Runtime
2. **Настройка проекта** Xcode
3. **Подпись библиотек** для совместимости
4. **Проверка совместимости**

## Ручная настройка

Если автоматическая настройка не работает, выполните шаги вручную:

### Шаг 1: Сборка библиотек с поддержкой Hardened Runtime

```bash
./build_whisper_libs.sh
```

Этот скрипт:
- Устанавливает флаги компиляции для Hardened Runtime
- Собирает библиотеки whisper.cpp
- Копирует библиотеки в проект

### Шаг 2: Настройка проекта Xcode

```bash
./setup_hardened_runtime.sh
```

Или вручную в Xcode:
1. Откройте `WhiteNoise.xcodeproj`
2. Выберите target `WhiteNoise`
3. Перейдите в `Signing & Capabilities`
4. Включите `Hardened Runtime`

### Шаг 3: Подпись библиотек

```bash
./sign_libraries.sh
```

Этот скрипт подписывает все библиотеки для совместимости с Hardened Runtime.

## Настройка в Xcode

### Включение Hardened Runtime

1. Откройте проект в Xcode
2. Выберите target `WhiteNoise`
3. Перейдите в `Signing & Capabilities`
4. Нажмите `+ Capability`
5. Добавьте `Hardened Runtime`

### Настройка исключений

Если библиотеки вызывают проблемы с Hardened Runtime:

1. В `Signing & Capabilities` найдите `Hardened Runtime`
2. В разделе `Runtime Exceptions` добавьте:
   - `Allow DYLD Environment Variables` - если библиотеки используют переменные окружения
   - `Disable Library Validation` - для библиотек без подписи (не рекомендуется)

### Настройка подписи

1. В `Signing & Capabilities` убедитесь, что:
   - `Automatically manage signing` включено
   - Выбран правильный Team
   - Bundle Identifier уникален

## Проверка совместимости

### Проверка подписи приложения

```bash
codesign -dv /path/to/WhiteNoise.app
```

### Проверка подписи библиотек

```bash
codesign -dv WhiteNoise/Resources/libwhisper.dylib
```

### Проверка архитектуры

```bash
file WhiteNoise/Resources/*.dylib
```

## Решение проблем

### Ошибка "Library not loaded"

Если появляется ошибка загрузки библиотек:

1. Убедитесь, что библиотеки подписаны:
   ```bash
   ./sign_libraries.sh
   ```

2. Добавьте библиотеки в исключения Hardened Runtime в Xcode

3. Проверьте, что библиотеки собраны для правильной архитектуры

### Ошибка "Code signing is required"

Если появляется ошибка подписи:

1. Убедитесь, что у вас есть сертификат разработчика Apple
2. Проверьте настройки подписи в Xcode
3. Попробуйте пересобрать проект

### Ошибка "Hardened Runtime violation"

Если появляется нарушение Hardened Runtime:

1. Проверьте логи в Console.app
2. Добавьте необходимые исключения в Xcode
3. Убедитесь, что все библиотеки совместимы

## Дополнительные настройки безопасности

### App Sandbox

Для дополнительной безопасности включите App Sandbox:

1. В `Signing & Capabilities` добавьте `App Sandbox`
2. Настройте необходимые разрешения:
   - `Audio Input` - для записи звука
   - `File Access` - для доступа к файлам моделей
   - `Network` - если приложение использует сеть

### Notarization

Для распространения приложения через App Store или вне его:

1. Подпишите приложение с сертификатом разработчика
2. Загрузите приложение для notarization:
   ```bash
   xcrun notarytool submit WhiteNoise.app --wait
   ```
3. Добавьте ticket в приложение:
   ```bash
   xcrun stapler staple WhiteNoise.app
   ```

## Полезные команды

### Проверка подписи

```bash
# Проверка подписи приложения
codesign -dv WhiteNoise.app

# Проверка подписи библиотеки
codesign -dv WhiteNoise/Resources/libwhisper.dylib

# Проверка всех подписей в приложении
codesign -dv --deep WhiteNoise.app
```

### Проверка архитектуры

```bash
# Проверка архитектуры приложения
lipo -info WhiteNoise.app/Contents/MacOS/WhiteNoise

# Проверка архитектуры библиотек
file WhiteNoise/Resources/*.dylib
```

### Проверка зависимостей

```bash
# Проверка зависимостей приложения
otool -L WhiteNoise.app/Contents/MacOS/WhiteNoise

# Проверка зависимостей библиотеки
otool -L WhiteNoise/Resources/libwhisper.dylib
```

## Заключение

Hardened Runtime значительно повышает безопасность приложения, но может потребовать дополнительной настройки для работы с внешними библиотеками. Следуйте инструкциям выше для правильной настройки.

Если у вас возникли проблемы, проверьте:
1. Логи Xcode и Console.app
2. Подпись всех компонентов
3. Совместимость библиотек с Hardened Runtime
4. Настройки исключений в Xcode 