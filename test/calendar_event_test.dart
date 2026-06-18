import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';

CalendarEvent _createEvent({
  DateTime? start,
  DateTime? end,
  RepeatType repeatType = RepeatType.none,
  EventCategory category = EventCategory.personal,
  bool isCompleted = false,
  DateTime? dueDate,
}) {
  return CalendarEvent(
    id: '1',
    title: 'Test',
    start: start ?? DateTime(2025, 1, 15, 10, 0),
    end: end ?? DateTime(2025, 1, 15, 11, 0),
    color: 0,
    repeatType: repeatType,
    category: category,
    isCompleted: isCompleted,
    dueDate: dueDate,
  );
}

void main() {
  group('isVisibleOnDate — обычные события (RepeatType.none)', () {
    test('событие видно в тот же день', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
    });

    test('событие не видно на день раньше', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 14)), isFalse);
    });

    test('событие не видно на день позже', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 16)), isFalse);
    });

    test('многодневное событие видно во все дни диапазона', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 10),
        end: DateTime(2025, 1, 15),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 9)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 10)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 12)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 16)), isFalse);
    });

    test('событие где start == end видно только в один день', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 16)), isFalse);
    });
  });

  group('isVisibleOnDate — задачи с дедлайном', () {
    test('задача видна от start до dueDate', () {
      final event = _createEvent(
        category: EventCategory.task,
        start: DateTime(2025, 1, 10),
        end: DateTime(2025, 1, 10),
        dueDate: DateTime(2025, 1, 20),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 9)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 10)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 20)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 21)), isFalse);
    });

    test('выполненная задача не видна после start', () {
      final event = _createEvent(
        category: EventCategory.task,
        start: DateTime(2025, 1, 10),
        end: DateTime(2025, 1, 10),
        dueDate: DateTime(2025, 1, 20),
        isCompleted: true,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 10)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isFalse);
    });

    test('задача без дедлайна видна только в день start', () {
      final event = _createEvent(
        category: EventCategory.task,
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15),
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 16)), isFalse);
    });
  });

  group('isVisibleOnDate — ежедневное повторение', () {
    test('событие видно каждый день после start', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15),
        repeatType: RepeatType.daily,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 14)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 16)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 12, 31)), isTrue);
    });
  });

  group('isVisibleOnDate — еженедельное повторение', () {
    test('событие видно каждые 7 дней', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 13), // понедельник
        end: DateTime(2025, 1, 13),
        repeatType: RepeatType.weekly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 13)), isTrue); // пн
      expect(event.isVisibleOnDate(DateTime(2025, 1, 14)), isFalse); // вт
      expect(event.isVisibleOnDate(DateTime(2025, 1, 20)), isTrue); // пн +7
      expect(event.isVisibleOnDate(DateTime(2025, 1, 27)), isTrue); // пн +14
    });

    test('не видно в промежуточные дни', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 13),
        end: DateTime(2025, 1, 13),
        repeatType: RepeatType.weekly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 1, 18)), isFalse);
    });
  });

  group('isVisibleOnDate — ежемесячное повторение', () {
    test('событие видно в один и тот же день месяца', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15),
        repeatType: RepeatType.monthly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 2, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 3, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 12, 15)), isTrue);
    });

    test('не видно в другие дни месяца', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15),
        repeatType: RepeatType.monthly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 1, 14)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 2, 14)), isFalse);
    });
  });

  group('isVisibleOnDate — ежегодное повторение', () {
    test('событие видно в один и тот же день и месяц', () {
      final event = _createEvent(
        start: DateTime(2025, 3, 15),
        end: DateTime(2025, 3, 15),
        repeatType: RepeatType.yearly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 3, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2026, 3, 15)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2027, 3, 15)), isTrue);
    });

    test('не видно в другие дни', () {
      final event = _createEvent(
        start: DateTime(2025, 3, 15),
        end: DateTime(2025, 3, 15),
        repeatType: RepeatType.yearly,
      );
      expect(event.isVisibleOnDate(DateTime(2026, 3, 14)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2026, 4, 15)), isFalse);
    });
  });

  group('isVisibleOnDate — граничные случаи', () {
    test('повторяющееся событие не видно до даты start', () {
      final event = _createEvent(
        start: DateTime(2025, 6, 15),
        end: DateTime(2025, 6, 15),
        repeatType: RepeatType.daily,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 6, 14)), isFalse);
      expect(event.isVisibleOnDate(DateTime(2025, 6, 15)), isTrue);
    });

    test('февраль — событие 31-го числа не показывается в феврале', () {
      final event = _createEvent(
        start: DateTime(2025, 1, 31),
        end: DateTime(2025, 1, 31),
        repeatType: RepeatType.monthly,
      );
      expect(event.isVisibleOnDate(DateTime(2025, 2, 28)), isFalse);
    });

    test('февраль — високосный год (29 дней)', () {
      final event = _createEvent(
        start: DateTime(2024, 1, 29),
        end: DateTime(2024, 1, 29),
        repeatType: RepeatType.monthly,
      );
      expect(event.isVisibleOnDate(DateTime(2024, 2, 29)), isTrue);
      expect(event.isVisibleOnDate(DateTime(2025, 2, 28)), isFalse);
    });
  });
}
