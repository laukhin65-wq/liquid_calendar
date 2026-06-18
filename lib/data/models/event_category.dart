import 'package:flutter/material.dart';

enum EventCategory {
  work,
  sport,
  study,
  personal,
  important,
  task,
  birthday,
  holiday,
}

extension EventCategoryExtension on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.work:
        return 'Работа';
      case EventCategory.sport:
        return 'Спорт';
      case EventCategory.study:
        return 'Учёба';
      case EventCategory.personal:
        return 'Личное';
      case EventCategory.important:
        return 'Важное';
      case EventCategory.task:
        return 'Задача';
      case EventCategory.birthday:
        return 'День рождения';
      case EventCategory.holiday:
        return 'Праздник';
    }
  }

  /// Цвет категории — единый источник для месяца/дня и кружочков выбора.
  Color get color {
    switch (this) {
      case EventCategory.work:
        return Color(0xFF2E7D32);
      case EventCategory.sport:
        return Colors.orange;
      case EventCategory.study:
        return Colors.purple;
      case EventCategory.personal:
        return Colors.blue;
      case EventCategory.important:
        return Colors.red;
      case EventCategory.task:
        return Colors.yellow;
      case EventCategory.birthday:
        return Color(0xFF66BB6A);
      case EventCategory.holiday:
        return Color(0xFFEF5350);
    }
  }
}