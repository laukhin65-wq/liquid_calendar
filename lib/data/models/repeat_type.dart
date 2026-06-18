enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

extension RepeatTypeExtension on RepeatType {
  String get label {
    switch (this) {
      case RepeatType.none:
        return 'Не повторять';

      case RepeatType.daily:
        return 'Каждый день';

      case RepeatType.weekly:
        return 'Каждую неделю';

      case RepeatType.monthly:
        return 'Каждый месяц';

      case RepeatType.yearly:
        return 'Каждый год';
    }
  }
}