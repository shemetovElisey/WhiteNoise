# 🚀 Быстрый старт WhiteNoise

## Для новых пользователей

### 1. Скачайте проект
```bash
git clone <your-repo-url>
cd WhiteNoise
```

### 2. Запустите автоматическую настройку
```bash
./setup_project.sh
```

### 3. Откройте в Xcode
```bash
open WhiteNoise.xcodeproj
```

### 4. Соберите и запустите
- Выберите устройство (iPhone/Simulator)
- Нажмите `Cmd+R`

**Готово!** 🎉

---

## Что делает setup_project.sh?

✅ Клонирует whisper.cpp (если нужно)  
✅ Собирает библиотеки whisper  
✅ Копирует все файлы в проект  
✅ Настраивает права доступа  

---

## Если что-то пошло не так

### Ошибка "permission denied"
```bash
chmod +x setup_project.sh
./setup_project.sh
```

### Ошибка "library not found"
```bash
./build_whisper_libs.sh
```

### Ошибка в Xcode
1. Очистите проект: `Cmd+Shift+K`
2. Пересоберите: `Cmd+B`

---

## Дополнительная информация

- 📖 [README.md](README.md) - полная документация
- 🔧 [INSTALL_WHISPER.md](INSTALL_WHISPER.md) - подробные инструкции
- 🐛 [Устранение неполадок](README.md#-устранение-неполадок)

---

**Приятного использования! 🎤📱** 