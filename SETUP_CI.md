# 🚀 Настройка CI/CD Пайплайнов

Этот документ содержит инструкции по настройке и использованию GitHub Actions пайплайнов для проекта WhiteNoise.

## 📋 Что было добавлено

### Пайплайны GitHub Actions

1. **`ci.yml`** - Основной CI пайплайн
2. **`release.yml`** - Сборка релизных версий
3. **`code-quality.yml`** - Проверка качества кода
4. **`create-release.yml`** - Автоматическое создание релизов
5. **`security.yml`** - Проверка безопасности
6. **`compatibility.yml`** - Тестирование совместимости
7. **`dependency-update.yml`** - Автоматическое обновление зависимостей

### Конфигурационные файлы

1. **`.swiftlint.yml`** - Настройки SwiftLint
2. **`.github/workflows/README.md`** - Документация пайплайнов

## 🛠️ Настройка

### 1. Активация пайплайнов

Пайплайны автоматически активируются при push в репозиторий. Убедитесь, что:

- ✅ Репозиторий находится на GitHub
- ✅ Включены GitHub Actions в настройках репозитория
- ✅ Есть права на создание workflow runs

### 2. Настройка секретов (опционально)

Для полной функциональности добавьте секреты в настройках репозитория:

```bash
# Перейдите в Settings → Secrets and variables → Actions
# Добавьте следующие секреты:

APPLE_DEVELOPER_ID=your_developer_id
APPLE_DEVELOPER_CERT=your_certificate_base64
```

### 3. Настройка SwiftLint

SwiftLint уже настроен, но для локальной разработки:

```bash
# Установка
brew install swiftlint

# Проверка
swiftlint lint

# Автоисправление
swiftlint autocorrect
```

## 🔄 Использование

### Автоматические триггеры

- **Push в main/develop** → Запуск CI, Code Quality, Security
- **Pull Request** → Запуск CI, Code Quality, Security
- **Создание тега v*** → Запуск Release Build, Create Release
- **Еженедельно** → Security Check, Compatibility Test, Dependency Update

### Ручной запуск

1. Перейдите в **Actions** вкладку GitHub
2. Выберите нужный пайплайн
3. Нажмите **Run workflow**
4. Выберите ветку и параметры

### Мониторинг

- **Actions** вкладка → Статус всех пайплайнов
- **Security** вкладка → Результаты анализа безопасности
- **Releases** → Автоматически созданные релизы

## 📊 Что проверяется

### CI (Continuous Integration)
- ✅ Сборка проекта для iOS симулятора
- ✅ Запуск всех тестов
- ✅ Загрузка результатов тестов

### Code Quality
- ✅ Стиль кода (SwiftLint)
- ✅ Автоматическое исправление проблем
- ✅ Коммит исправлений

### Security
- ✅ Сканирование уязвимостей (Trivy)
- ✅ Анализ кода (CodeQL)
- ✅ Поиск секретов в коде
- ✅ Проверка Swift кода

### Compatibility
- ✅ Сборка для iOS 16.0, 17.0, 18.0
- ✅ Тестирование на iPhone 13, 14, 15
- ✅ Загрузка результатов тестов

### Release Build
- ✅ Сборка для iOS (архив + IPA)
- ✅ Сборка для macOS (архив)
- ✅ Загрузка артефактов

## 🐛 Устранение неполадок

### Ошибки сборки

1. **Проверьте версию Xcode**
   ```yaml
   # В пайплайнах используется Xcode 15.0
   xcode-version: '15.0'
   ```

2. **Проверьте схему проекта**
   ```bash
   # Убедитесь, что схема WhiteNoise существует
   xcodebuild -list -project WhiteNoise.xcodeproj
   ```

3. **Проверьте зависимости**
   ```bash
   # Обновите Swift Package Manager зависимости
   xcodebuild -resolvePackageDependencies -project WhiteNoise.xcodeproj
   ```

### Ошибки тестов

1. **Проверьте симулятор**
   ```bash
   # Список доступных симуляторов
   xcrun simctl list devices
   ```

2. **Проверьте права доступа**
   ```bash
   # Убедитесь, что тесты имеют доступ к файлам
   chmod +x WhiteNoise/Tests/*
   ```

### Ошибки SwiftLint

1. **Обновите конфигурацию**
   ```yaml
   # В .swiftlint.yml
   disabled_rules:
     - trailing_whitespace
   ```

2. **Добавьте исключения**
   ```swift
   // swiftlint:disable:next line_length
   let veryLongLine = "This is a very long line that exceeds the limit"
   ```

## 🔧 Кастомизация

### Добавление новых проверок

1. Создайте новый `.yml` файл в `.github/workflows/`
2. Определите триггеры и steps
3. Добавьте документацию

### Изменение расписания

```yaml
# В пайплайнах с schedule
on:
  schedule:
    - cron: '0 2 * * 1' # Каждый понедельник в 2:00
```

### Добавление новых платформ

```yaml
# В compatibility.yml
strategy:
  matrix:
    ios-version: ['16.0', '17.0', '18.0', '19.0']
    device: ['iPhone 15', 'iPhone 14', 'iPhone 13', 'iPhone 12']
```

## 📈 Метрики и отчеты

### Статистика пайплайнов

- **Время выполнения** каждого пайплайна
- **Успешность** сборок и тестов
- **Количество** найденных проблем

### Артефакты

- **test-results** - Результаты тестов
- **WhiteNoise-iOS-*** - iOS сборки
- **WhiteNoise-macOS-*** - macOS сборки
- **compatibility-test-*** - Результаты совместимости

## 🔗 Полезные ссылки

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SwiftLint Documentation](https://realm.github.io/SwiftLint/)
- [CodeQL Documentation](https://codeql.github.com/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи выполнения в GitHub Actions
2. Создайте Issue с описанием проблемы
3. Приложите скриншоты ошибок и логи
4. Укажите версию Xcode и macOS

---

**Примечание**: Пайплайны настроены для работы без дополнительной конфигурации. Все необходимые зависимости и инструменты устанавливаются автоматически.