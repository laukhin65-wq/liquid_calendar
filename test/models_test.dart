import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';
import 'package:liquid_calendar/data/models/reminder_offset.dart';

void main() {
  group('EventCategory — label', () {
    test('work label', () => expect(EventCategory.work.label, 'Работа'));
    test('sport label', () => expect(EventCategory.sport.label, 'Спорт'));
    test('study label', () => expect(EventCategory.study.label, 'Учёба'));
    test('personal label', () => expect(EventCategory.personal.label, 'Личное'));
    test('important label', () => expect(EventCategory.important.label, 'Важное'));
    test('task label', () => expect(EventCategory.task.label, 'Задача'));
    test('birthday label', () => expect(EventCategory.birthday.label, 'День рождения'));
    test('holiday label', () => expect(EventCategory.holiday.label, 'Праздник'));
  });

  group('EventCategory — color', () {
    test('work color is green', () => expect(EventCategory.work.color, const Color(0xFF2E7D32)));
    test('sport color is orange', () => expect(EventCategory.sport.color, Colors.orange));
    test('study color is purple', () => expect(EventCategory.study.color, Colors.purple));
    test('personal color is blue', () => expect(EventCategory.personal.color, Colors.blue));
    test('important color is red', () => expect(EventCategory.important.color, Colors.red));
    test('task color is yellow', () => expect(EventCategory.task.color, Colors.yellow));
    test('birthday color is green', () => expect(EventCategory.birthday.color, const Color(0xFF66BB6A)));
    test('holiday color is red', () => expect(EventCategory.holiday.color, const Color(0xFFEF5350)));
  });

  group('RepeatType — label', () {
    test('none label', () => expect(RepeatType.none.label, 'Не повторять'));
    test('daily label', () => expect(RepeatType.daily.label, 'Каждый день'));
    test('weekly label', () => expect(RepeatType.weekly.label, 'Каждую неделю'));
    test('monthly label', () => expect(RepeatType.monthly.label, 'Каждый месяц'));
    test('yearly label', () => expect(RepeatType.yearly.label, 'Каждый год'));
  });

  group('ReminderOffset — label', () {
    test('none label', () => expect(ReminderOffset.none.label, 'Нет'));
    test('min5 label', () => expect(ReminderOffset.min5.label, 'За 5 минут'));
    test('min15 label', () => expect(ReminderOffset.min15.label, 'За 15 минут'));
    test('min30 label', () => expect(ReminderOffset.min30.label, 'За 30 минут'));
    test('hour1 label', () => expect(ReminderOffset.hour1.label, 'За 1 час'));
    test('day1 label', () => expect(ReminderOffset.day1.label, 'За 1 день'));
  });

  group('ReminderOffset — minutes', () {
    test('none minutes', () => expect(ReminderOffset.none.minutes, isNull));
    test('min5 minutes', () => expect(ReminderOffset.min5.minutes, 5));
    test('min15 minutes', () => expect(ReminderOffset.min15.minutes, 15));
    test('min30 minutes', () => expect(ReminderOffset.min30.minutes, 30));
    test('hour1 minutes', () => expect(ReminderOffset.hour1.minutes, 60));
    test('day1 minutes', () => expect(ReminderOffset.day1.minutes, 1440));
  });

  group('ReminderOffset — fromMinutes', () {
    test('null returns none', () => expect(ReminderOffsetX.fromMinutes(null), ReminderOffset.none));
    test('5 returns min5', () => expect(ReminderOffsetX.fromMinutes(5), ReminderOffset.min5));
    test('15 returns min15', () => expect(ReminderOffsetX.fromMinutes(15), ReminderOffset.min15));
    test('30 returns min30', () => expect(ReminderOffsetX.fromMinutes(30), ReminderOffset.min30));
    test('60 returns hour1', () => expect(ReminderOffsetX.fromMinutes(60), ReminderOffset.hour1));
    test('1440 returns day1', () => expect(ReminderOffsetX.fromMinutes(1440), ReminderOffset.day1));
    test('unknown returns none', () => expect(ReminderOffsetX.fromMinutes(999), ReminderOffset.none));
  });
}
