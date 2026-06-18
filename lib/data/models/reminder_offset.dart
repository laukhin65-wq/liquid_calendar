/// За сколько до начала события показать напоминание.
///
/// Кладётся в `lib/data/models/reminder_offset.dart`.
enum ReminderOffset {
  none,
  min5,
  min15,
  min30,
  hour1,
  day1,
}

extension ReminderOffsetX on ReminderOffset {
  /// Сколько минут ДО начала события.
  /// `null` — напоминание выключено («Нет»).
  int? get minutes => switch (this) {
        ReminderOffset.none => null,
        ReminderOffset.min5 => 5,
        ReminderOffset.min15 => 15,
        ReminderOffset.min30 => 30,
        ReminderOffset.hour1 => 60,
        ReminderOffset.day1 => 1440,
      };

  /// Текст для выпадающего списка.
  String get label => switch (this) {
        ReminderOffset.none => 'Нет',
        ReminderOffset.min5 => 'За 5 минут',
        ReminderOffset.min15 => 'За 15 минут',
        ReminderOffset.min30 => 'За 30 минут',
        ReminderOffset.hour1 => 'За 1 час',
        ReminderOffset.day1 => 'За 1 день',
      };

  /// Восстановить значение из сохранённых минут (поле события).
  static ReminderOffset fromMinutes(int? m) => switch (m) {
        5 => ReminderOffset.min5,
        15 => ReminderOffset.min15,
        30 => ReminderOffset.min30,
        60 => ReminderOffset.hour1,
        1440 => ReminderOffset.day1,
        _ => ReminderOffset.none,
      };
}
