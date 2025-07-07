# WhiteNoise Logging System Guide

## Overview

The WhiteNoise app includes a comprehensive logging system that allows users to monitor, debug, and troubleshoot the application. The logging system is fully integrated throughout the app and provides real-time visibility into all major operations.

## Features

### Log Levels
- **DEBUG** 🔍 - Detailed debugging information
- **INFO** ℹ️ - General information about app operations
- **WARNING** ⚠️ - Potential issues that don't stop operation
- **ERROR** ❌ - Errors that affect functionality

### Components Tracked
- **AppDelegate** - App lifecycle, shortcuts, notifications
- **VoiceRecorder** - Audio recording operations
- **SpeechManager** - Speech recognition coordination
- **LocalSpeechRecognizer** - Whisper model operations
- **WhisperModelManager** - Model downloads and management

## Accessing the Logs

### Method 1: Through Settings
1. Open the WhiteNoise app
2. Click on the microphone icon in the menu bar
3. Select "Настройки" (Settings)
4. Scroll down to "Системные логи" (System Logs)
5. Click "Открыть логи" (Open Logs)

### Method 2: Direct Access
The logs view can be accessed programmatically through the app's settings interface.

## Log Viewer Interface

### Main Features
- **Real-time Updates** - Logs appear as they're generated
- **Filtering** - Filter by log level and component
- **Search** - Search through log messages and components
- **Export** - Export logs to text files
- **Clear** - Clear all logs

### Interface Elements

#### Header Section
- Shows total log count and filtered count
- Clear and Export buttons
- Logging enable/disable toggle

#### Filter Section
- **Search Bar** - Search through log content
- **Level Filter** - Filter by DEBUG, INFO, WARNING, ERROR
- **Component Filter** - Filter by specific app components
- **Settings Toggle** - Enable/disable logging

#### Log Display
- **Timestamps** - Precise timing of events
- **Level Indicators** - Color-coded log levels with icons
- **Component Tags** - Shows which part of the app generated the log
- **Message Content** - Detailed log information

## Using the Log System

### Viewing Logs
1. Open the logs view
2. Logs are displayed in reverse chronological order (newest first)
3. Use filters to focus on specific issues
4. Scroll through logs to see historical data

### Filtering Logs
- **By Level**: Select specific log levels to focus on errors or warnings
- **By Component**: Filter by specific app components (e.g., VoiceRecorder, SpeechManager)
- **By Search**: Enter keywords to find specific log entries

### Exporting Logs
1. Click the "Экспорт" (Export) button
2. Choose export options:
   - Export all logs or only filtered logs
   - Include/exclude timestamps
   - Include/exclude log levels
   - Include/exclude component names
3. Click "Экспортировать" (Export)
4. Logs are saved to your Documents folder with timestamp

### Clearing Logs
1. Click the "Очистить" (Clear) button
2. Confirm the action
3. All logs are permanently deleted

## Common Use Cases

### Debugging Recording Issues
1. Open logs and filter by "VoiceRecorder" component
2. Start a recording session
3. Look for:
   - Permission status messages
   - File creation/recording status
   - Error messages during recording

### Troubleshooting Speech Recognition
1. Filter by "LocalSpeechRecognizer" and "SpeechManager"
2. Perform a voice recognition
3. Check for:
   - Model loading status
   - Audio conversion messages
   - Whisper execution results
   - Error messages

### Monitoring Model Downloads
1. Filter by "WhisperModelManager"
2. Download a new model
3. Monitor:
   - Download progress
   - File verification
   - Installation status

### App Startup Issues
1. Filter by "AppDelegate"
2. Restart the app
3. Check for:
   - Initialization messages
   - Permission requests
   - Shortcut registration status

## Log Examples

### Successful Recording Session
```
[2025-07-08 00:15:30.123] [INFO] [VoiceRecorder] VoiceRecorder инициализирован
[2025-07-08 00:15:30.125] [INFO] [VoiceRecorder] Разрешение на микрофон уже предоставлено
[2025-07-08 00:15:35.456] [INFO] [VoiceRecorder] Запрос на начало записи
[2025-07-08 00:15:35.458] [INFO] [VoiceRecorder] Разрешение на микрофон подтверждено, начинаем запись
[2025-07-08 00:15:35.460] [INFO] [VoiceRecorder] Запись начата успешно
[2025-07-08 00:15:40.789] [INFO] [VoiceRecorder] Останавливаем запись
[2025-07-08 00:15:40.791] [INFO] [VoiceRecorder] Файл записан: /path/to/voice_input.wav, размер: 123456 байт
```

### Error Scenario
```
[2025-07-08 00:16:00.123] [ERROR] [LocalSpeechRecognizer] Модель не найдена по пути /path/to/model
[2025-07-08 00:16:00.125] [WARNING] [SpeechManager] Ошибка локального распознавания: Model not found
[2025-07-08 00:16:00.127] [ERROR] [VoiceRecorder] Ошибка распознавания: Model not found
```

### Model Download
```
[2025-07-08 00:17:00.123] [INFO] [WhisperModelManager] Начинаем загрузку модели: Tiny (39 MB)
[2025-07-08 00:17:00.125] [INFO] [WhisperModelManager] Директория для моделей создана/проверена: /path/to/models
[2025-07-08 00:17:05.456] [INFO] [WhisperModelManager] Загрузка завершена успешно
```

## Best Practices

### For Users
1. **Keep Logging Enabled** - Only disable if you're experiencing performance issues
2. **Export Logs Before Clearing** - Save important logs before clearing
3. **Use Filters** - Focus on specific components when troubleshooting
4. **Check Logs Regularly** - Monitor for warnings and errors

### For Developers
1. **Use Appropriate Log Levels** - Don't log everything as INFO
2. **Include Context** - Provide enough information to understand the issue
3. **Log Errors with Details** - Include error descriptions and stack traces
4. **Use Consistent Component Names** - Makes filtering more effective

## Troubleshooting

### Common Issues

#### No Logs Appearing
- Check if logging is enabled in the settings
- Restart the app to see initialization logs
- Check if the app has proper permissions

#### Performance Issues
- Reduce the maximum log entries (default: 1000)
- Clear old logs regularly
- Disable logging temporarily if needed

#### Export Failures
- Check if you have write permissions to Documents folder
- Ensure sufficient disk space
- Try exporting smaller log sets

### Getting Help
When reporting issues to support:
1. Export logs with full details enabled
2. Include the time period when the issue occurred
3. Filter logs by relevant components
4. Note any error messages or warnings

## Technical Details

### Log Storage
- Logs are stored in memory during app runtime
- Maximum 1000 entries by default (configurable)
- Logs are lost when app is closed (export to preserve)

### Performance Impact
- Minimal impact on app performance
- Log entries are limited to prevent memory issues
- Logging can be disabled if needed

### Integration Points
The logging system is integrated into:
- App initialization and lifecycle
- Audio recording operations
- Speech recognition pipeline
- Model management
- Error handling throughout the app

## Conclusion

The WhiteNoise logging system provides comprehensive visibility into app operations, making it easy to diagnose issues, monitor performance, and understand app behavior. Regular use of the logging system will help maintain optimal app performance and quickly resolve any issues that arise. 