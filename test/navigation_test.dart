import 'package:flutter_test/flutter_test.dart';

enum CalendarViewType { day, week, month, year }

/// Извлекаемая логика навигации для тестирования.
/// Возвращает новую дату без副作用 (HTTP, WidgetService).
DateTime navigateDate(DateTime current, CalendarViewType view, int delta) {
  switch (view) {
    case CalendarViewType.day:
      return current.add(Duration(days: delta));

    case CalendarViewType.week:
      return current.add(Duration(days: 7 * delta));

    case CalendarViewType.month:
      final targetMonth = current.month + delta;
      final targetYear =
          current.year + (targetMonth > 12 ? 1 : targetMonth < 1 ? -1 : 0);
      final m = targetMonth > 12 ? 1 : targetMonth < 1 ? 12 : targetMonth;
      final maxDays = DateTime(targetYear, m + 1, 0).day;
      return DateTime(targetYear, m, current.day.clamp(1, maxDays));

    case CalendarViewType.year:
      return DateTime(
        current.year + delta,
        current.month,
        current.day,
      );
  }
}

void main() {
  group('navigateDate — день', () {
    test('вперёд на 1 день', () {
      final result = navigateDate(
        DateTime(2025, 1, 15),
        CalendarViewType.day,
        1,
      );
      expect(result, DateTime(2025, 1, 16));
    });

    test('назад на 1 день', () {
      final result = navigateDate(
        DateTime(2025, 1, 15),
        CalendarViewType.day,
        -1,
      );
      expect(result, DateTime(2025, 1, 14));
    });

    test('из 1 января вперёд — 2 января', () {
      final result = navigateDate(
        DateTime(2025, 1, 1),
        CalendarViewType.day,
        1,
      );
      expect(result, DateTime(2025, 1, 2));
    });

    test('из 1 января назад — 31 декабря прошлого года', () {
      final result = navigateDate(
        DateTime(2025, 1, 1),
        CalendarViewType.day,
        -1,
      );
      expect(result, DateTime(2024, 12, 31));
    });
  });

  group('navigateDate — неделя', () {
    test('вперёд на 7 дней', () {
      final result = navigateDate(
        DateTime(2025, 1, 13), // понедельник
        CalendarViewType.week,
        1,
      );
      expect(result, DateTime(2025, 1, 20));
    });

    test('назад на 7 дней', () {
      final result = navigateDate(
        DateTime(2025, 1, 13),
        CalendarViewType.week,
        -1,
      );
      expect(result, DateTime(2025, 1, 6));
    });

    test('из 1 января вперёд — 8 января', () {
      final result = navigateDate(
        DateTime(2025, 1, 1),
        CalendarViewType.week,
        1,
      );
      expect(result, DateTime(2025, 1, 8));
    });
  });

  group('navigateDate — месяц', () {
    test('вперёд на 1 месяц', () {
      final result = navigateDate(
        DateTime(2025, 1, 15),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2025, 2, 15));
    });

    test('назад на 1 месяц', () {
      final result = navigateDate(
        DateTime(2025, 1, 15),
        CalendarViewType.month,
        -1,
      );
      expect(result, DateTime(2024, 12, 15));
    });

    test('из января вперёд — февраль', () {
      final result = navigateDate(
        DateTime(2025, 1, 20),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2025, 2, 20));
    });

    test('из февраля назад — январь', () {
      final result = navigateDate(
        DateTime(2025, 2, 20),
        CalendarViewType.month,
        -1,
      );
      expect(result, DateTime(2025, 1, 20));
    });

    test('31 января → 28 февраля (год не високосный)', () {
      final result = navigateDate(
        DateTime(2025, 1, 31),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2025, 2, 28));
    });

    test('31 января → 29 февраля (високосный год)', () {
      final result = navigateDate(
        DateTime(2024, 1, 31),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2024, 2, 29));
    });

    test('31 марта → 30 апреля', () {
      final result = navigateDate(
        DateTime(2025, 3, 31),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2025, 4, 30));
    });

    test('30 ноября → 30 декабря', () {
      final result = navigateDate(
        DateTime(2025, 11, 30),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2025, 12, 30));
    });

    test('31 декабря → 31 января следующего года', () {
      final result = navigateDate(
        DateTime(2025, 12, 31),
        CalendarViewType.month,
        1,
      );
      expect(result, DateTime(2026, 1, 31));
    });

    test('1 января → 1 декабря прошлого года', () {
      final result = navigateDate(
        DateTime(2025, 1, 1),
        CalendarViewType.month,
        -1,
      );
      expect(result, DateTime(2024, 12, 1));
    });
  });

  group('navigateDate — год', () {
    test('вперёд на 1 год', () {
      final result = navigateDate(
        DateTime(2025, 6, 15),
        CalendarViewType.year,
        1,
      );
      expect(result, DateTime(2026, 6, 15));
    });

    test('назад на 1 год', () {
      final result = navigateDate(
        DateTime(2025, 6, 15),
        CalendarViewType.year,
        -1,
      );
      expect(result, DateTime(2024, 6, 15));
    });

    test('29 февраля високосного → 1 марта обычного', () {
      final result = navigateDate(
        DateTime(2024, 2, 29),
        CalendarViewType.year,
        1,
      );
      // DateTime автоматически корректирует 29 февраля → 1 марта
      expect(result, DateTime(2025, 3, 1));
    });
  });
}
