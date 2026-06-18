import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';

void main() {
  group('Repeat date calculation', () {
    test('weekly adds 7 days', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final result = addRepeat(date, RepeatType.weekly);
      expect(result, DateTime(2025, 1, 22, 10, 30));
    });

    test('monthly adds 1 month', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final result = addRepeat(date, RepeatType.monthly);
      expect(result, DateTime(2025, 2, 15, 10, 30));
    });

    test('yearly adds 1 year', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final result = addRepeat(date, RepeatType.yearly);
      expect(result, DateTime(2026, 1, 15, 10, 30));
    });

    test('daily adds 1 day', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final result = addRepeat(date, RepeatType.daily);
      expect(result, DateTime(2025, 1, 16, 10, 30));
    });

    test('none adds 1 day', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final result = addRepeat(date, RepeatType.none);
      expect(result, DateTime(2025, 1, 16, 10, 30));
    });

    test('monthly handles year boundary', () {
      final date = DateTime(2025, 12, 15, 10, 30);
      final result = addRepeat(date, RepeatType.monthly);
      expect(result, DateTime(2026, 1, 15, 10, 30));
    });

    test('yearly handles leap year', () {
      final date = DateTime(2024, 2, 29, 10, 30);
      final result = addRepeat(date, RepeatType.yearly);
      expect(result, DateTime(2025, 3, 1, 10, 30));
    });
  });
}

DateTime addRepeat(DateTime d, RepeatType repeatType) {
  switch (repeatType) {
    case RepeatType.weekly:
      return d.add(const Duration(days: 7));
    case RepeatType.monthly:
      return DateTime(d.year, d.month + 1, d.day, d.hour, d.minute);
    case RepeatType.yearly:
      return DateTime(d.year + 1, d.month, d.day, d.hour, d.minute);
    case RepeatType.daily:
      return d.add(const Duration(days: 1));
    case RepeatType.none:
      return d.add(const Duration(days: 1));
  }
}
