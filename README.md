# LIFE — Календарь жизни

Flutter-приложение для планирования событий, задач и отслеживания жизни.

## Возможности

- **Календарь** — день, неделя, месяц, год
- **События** — создание, редактирование, повторение
- **Задачи** — с дедлайнами и статусом выполнения
- **Категории** — работа, спорт, учёба, личное, важное, задачи, дни рождения, праздники
- **Напоминания** — гибкая настройка времени
- **Поиск** — по названию, категории, дате
- **Аналитика** — статистика по категориям, людям, местам
- **Темы** — светлая, тёмная, стеклянная (Liquid Glass)
- **Виджет** — информация о событиях на главном экране

## Архитектура

```
lib/
├── data/
│   ├── models/          # Модели данных
│   └── repositories/    # Репозитории
├── providers/           # State management (Provider)
├── screens/             # Экраны
│   ├── day/
│   ├── week/
│   ├── month/
│   └── year/
├── services/            # Бизнес-логика
├── theme/               # Темы оформления
└── widgets/             # Переиспользуемые виджеты
```

## Быстрый старт

```bash
# Установка зависимостей
flutter pub get

# Запуск на эмуляторе
flutter run

# Запуск тестов
flutter test

# Запуск с покрытием
flutter test --coverage
```

## Тесты

Проект содержит **163 unit-теста** с покрытием **69%**.

```bash
# Все тесты
flutter test

# С отчётом о покрытии
flutter test --coverage

# Просмотр отчёта
open coverage/lcov.info
```

### Структура тестов

| Файл | Что тестирует | Тестов |
|------|---------------|--------|
| `calendar_event_test.dart` | isVisibleOnDate | 18 |
| `navigation_test.dart` | Навигация по датам | 20 |
| `calendar_provider_test.dart` | Провайдер | 35 |
| `models_test.dart` | Модели и extension'ы | 40 |
| `services_test.dart` | Аналитические сервисы | 8 |
| `additional_test.dart` | ContactModel, LocationModel, ScheduleBuilder | 32 |
| `notification_service_test.dart` | Повторение дат | 7 |
| `widget_test.dart` | isMeeting | 3 |

## CI/CD

GitHub Actions автоматически запускает:

```yaml
- flutter analyze   # Статический анализ
- flutter test      # Unit-тесты
```

При каждом push в `main` или `master`.

## Технологии

- **Flutter** — UI фреймворк
- **Provider** — State management
- **Hive** — Локальное хранилище
- **flutter_local_notifications** — Уведомления
- **android_alarm_manager_plus** — Фоновые задачи

## Оптимизации

| Что | Описание |
|-----|----------|
| Кеширование | `filteredEvents` кешируется с инвалидацией |
| Pre-compute | Месячный/недельный/годовой виды |
| Убран polling | Виджет через MethodChannel |

## Лицензия

MIT
