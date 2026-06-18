import 'package:hive/hive.dart';
import 'event_category.dart';
import 'repeat_type.dart';


part 'calendar_event.g.dart';


@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime start;

  @HiveField(3)
  DateTime end;

  @HiveField(4)
  int color;

  @HiveField(5)
  RepeatType repeatType;

  @HiveField(6)
  EventCategory category;

  @HiveField(7)
  String? notificationId;

  /// За сколько минут ДО начала показать напоминание.
  /// `null` — напоминание выключено («Нет»).
  @HiveField(8)
  int? reminderMinutes;

  /// Место проведения (для «Мероприятия»).
  @HiveField(9)
  String? location;

  /// Широта места.
  @HiveField(17)
  double? locationLatitude;

  /// Долгота места.
  @HiveField(18)
  double? locationLongitude;

  /// Описание / дополнительная информация.
  @HiveField(10)
  String? description;

  /// Имена приглашённых контактов (из телефонной книги).
  @HiveField(11)
  List<String>? contacts;

  /// Пути прикреплённых файлов.
  @HiveField(12)
  List<String>? attachments;

  /// Смещение часового пояса события в минутах от UTC.
  /// `null` — использовать системный часовой пояс.
  @HiveField(13)
  int? timeZoneOffset;

  /// Задача выполнена (для категории task).
  @HiveField(14)
  bool isCompleted;

  /// Напоминания для дня рождения: список "дней_до_события:час:минута".
  /// Например: "0:9:0,1:10:0,2:18:30" = в день в 9:00, за день в 10:00, за 2 дня в 18:30.
  @HiveField(15)
  String? birthdayReminders;

  /// Дата окончания задачи (дедлайн).
  /// Задача отображается в каждом дне от [start] до [dueDate], пока не выполнена.
  @HiveField(16)
  DateTime? dueDate;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    required this.repeatType,
    required this.category,
    this.notificationId,
    this.reminderMinutes,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.description,
    this.contacts,
    this.attachments,
    this.timeZoneOffset,
    this.isCompleted = false,
    this.birthdayReminders,
    this.dueDate,
  });

  /// Встреча определяется автоматически: событие является встречей,
  /// если у него указан хотя бы один контакт.
  bool get isMeeting => contacts != null && contacts!.isNotEmpty;

  bool isVisibleOnDate(DateTime date) {
    final eventDate = DateTime(
      start.year,
      start.month,
      start.day,
    );

    final targetDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final isTask = category == EventCategory.task;

    if (repeatType == RepeatType.none) {
      if (isTask && dueDate != null && !isCompleted) {
        final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
        return !targetDate.isBefore(eventDate) && !targetDate.isAfter(due);
      }

      final endDate = DateTime(end.year, end.month, end.day);
      if (!endDate.isAfter(eventDate)) {
        return eventDate == targetDate;
      }

      return !targetDate.isBefore(eventDate) && !targetDate.isAfter(endDate);
    }

    if (targetDate.isBefore(eventDate)) {
      return false;
    }

    switch (repeatType) {
      case RepeatType.daily:
        return true;

      case RepeatType.weekly:
        return targetDate.difference(eventDate).inDays % 7 == 0;

      case RepeatType.monthly:
        return eventDate.day == targetDate.day;

      case RepeatType.yearly:
        return eventDate.day == targetDate.day &&
            eventDate.month == targetDate.month;

      case RepeatType.none:
        return false;
    }
  }
}
