import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../data/models/repeat_type.dart';
import '../data/models/calendar_event.dart';
import '../data/models/reminder_offset.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../data/models/event_category.dart';


enum CalendarViewType {
  day,
  week,
  month,
  year,
}

class CalendarProvider extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();

  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');
  final Box _settingsBox = Hive.box('settings');

  List<CalendarEvent> get events =>
      _eventsBox.values.toList();

  CalendarEvent? getEventById(String id) => _eventsBox.get(id);

  CalendarViewType currentView =
      CalendarViewType.month;

  // ── Фильтр категорий ──────────────────────────────────
  // Множество индексов включённых категорий. null = все включены.
  static const String _filterKey = 'visibleCategories';
  Set<int>? _visibleCategoryIndices;

  Set<int> get visibleCategoryIndices =>
      _visibleCategoryIndices ?? Set<int>.from(List.generate(EventCategory.values.length, (i) => i));

  bool isCategoryVisible(EventCategory cat) =>
      _visibleCategoryIndices == null || _visibleCategoryIndices!.contains(cat.index);

  List<CalendarEvent> get filteredEvents =>
      events.where((e) => isCategoryVisible(e.category)).toList();

  List<CalendarEvent> eventsForDate(DateTime date) =>
      filteredEvents.where((e) => e.isVisibleOnDate(date)).toList();

  void toggleCategory(EventCategory cat) {
    if (_visibleCategoryIndices == null) {
      _visibleCategoryIndices = Set<int>.from(
          List.generate(EventCategory.values.length, (i) => i));
      _visibleCategoryIndices!.remove(cat.index);
    } else {
      if (_visibleCategoryIndices!.contains(cat.index)) {
        _visibleCategoryIndices!.remove(cat.index);
      } else {
        _visibleCategoryIndices!.add(cat.index);
      }
    }
    _settingsBox.put(_filterKey, _visibleCategoryIndices!.toList());
    notifyListeners();
  }

  void setAllCategoriesVisible() {
    _visibleCategoryIndices = null;
    _settingsBox.delete(_filterKey);
    notifyListeners();
  }

  bool _filterExpanded = false;
  bool get filterExpanded => _filterExpanded;
  void toggleFilterExpanded() {
    _filterExpanded = !_filterExpanded;
    notifyListeners();
  }

  void _loadCategoryFilter() {
    final stored = _settingsBox.get(_filterKey);
    if (stored is List) {
      _visibleCategoryIndices = Set<int>.from(stored.cast<int>());
    }
  }

  CalendarProvider() {
    _loadCategoryFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetService.updateWidget();
      loadHolidaysForCurrentCountry(DateTime.now().year);
      loadHolidaysForCurrentCountry(DateTime.now().year + 1);
    });
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setView(CalendarViewType view) {
    currentView = view;
    notifyListeners();
  }

  void goToToday() {
    selectedDate = DateTime.now();
    notifyListeners();
  }

  void goPrevious() => _navigate(-1);

  void goNext() => _navigate(1);

  void _navigate(int delta) {
    switch (currentView) {
      case CalendarViewType.day:
        selectedDate = selectedDate.add(Duration(days: delta));
        break;

      case CalendarViewType.week:
        selectedDate = selectedDate.add(Duration(days: 7 * delta));
        break;

      case CalendarViewType.month:
        final targetMonth = selectedDate.month + delta;
        final targetYear = selectedDate.year + (targetMonth > 12 ? 1 : targetMonth < 1 ? -1 : 0);
        final m = targetMonth > 12 ? 1 : targetMonth < 1 ? 12 : targetMonth;
        final maxDays = DateTime(targetYear, m + 1, 0).day;
        selectedDate = DateTime(targetYear, m, selectedDate.day.clamp(1, maxDays));
        loadHolidaysForCurrentCountry(targetYear);
        break;

      case CalendarViewType.year:
        selectedDate = DateTime(
          selectedDate.year + delta,
          selectedDate.month,
          selectedDate.day,
        );
        loadHolidaysForCurrentCountry(selectedDate.year);
        break;
    }

    notifyListeners();
    WidgetService.updateWidget();
  }
  Future<void> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    required RepeatType repeatType,
    required EventCategory category,
    ReminderOffset reminder = ReminderOffset.none,
    int color = 0,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? description,
    List<String>? contacts,
    List<String>? attachments,
    int? timeZoneOffset,
    String? birthdayReminders,
    DateTime? dueDate,
  }) async {
    _validate(start, end);
    final event = _createEvent(
      title: title,
      start: start,
      end: end,
      repeatType: repeatType,
      category: category,
      reminder: reminder,
      color: color,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      description: description,
      contacts: contacts,
      attachments: attachments,
      timeZoneOffset: timeZoneOffset,
      birthdayReminders: birthdayReminders,
      dueDate: dueDate,
    );
    await _saveAndNotify(event);
  }

  void _validate(DateTime start, DateTime end) {
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      throw ArgumentError('Время окончания должно быть позже начала');
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _generateNotificationId() =>
      (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF).toString();

  CalendarEvent _createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    required RepeatType repeatType,
    required EventCategory category,
    required ReminderOffset reminder,
    required int color,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? description,
    List<String>? contacts,
    List<String>? attachments,
    int? timeZoneOffset,
    String? birthdayReminders,
    DateTime? dueDate,
  }) {
    return CalendarEvent(
      id: _generateId(),
      title: title,
      start: start,
      end: end,
      color: color,
      repeatType: repeatType,
      category: category,
      notificationId: _generateNotificationId(),
      reminderMinutes: reminder.minutes,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      description: description,
      contacts: contacts,
      attachments: attachments,
      timeZoneOffset: timeZoneOffset,
      birthdayReminders: birthdayReminders,
      dueDate: dueDate,
    );
  }

  Future<void> _saveAndNotify(CalendarEvent event) async {
    await _eventsBox.put(event.id, event);
    await _scheduleReminder(event);
    notifyListeners();
    WidgetService.updateWidget();
  }

  Future<void> deleteEvent(String eventId) async {
    final event = _eventsBox.get(eventId);

    // Если событие существовало и у него было уведомление — отменяем его
    if (event != null && event.notificationId != null) {
      await NotificationService.cancel(int.parse(event.notificationId!));
    }

    await _eventsBox.delete(eventId);

    notifyListeners();
    WidgetService.updateWidget();
  }

  // 2. Обновление существующего события (ПРИВЕДЕНО К ПОЛНОМУ ВИДУ)
  Future<void> updateEvent(CalendarEvent event) async {
    // ВАЖНО: сохраняем изменения объекта в локальную базу Hive
    await event.save();

    // Пересоздаём напоминание: время/повтор/смещение могли измениться.
    if (event.notificationId != null) {
      await NotificationService.cancel(int.parse(event.notificationId!));

      await _scheduleReminder(event);
    }

    notifyListeners();
    WidgetService.updateWidget();
  }

  /// Переключить статус выполнения задачи.
  Future<void> toggleTaskCompletion(CalendarEvent event) async {
    event.isCompleted = !event.isCompleted;
    await event.save();
    notifyListeners();
    WidgetService.updateWidget();
  }

  /* ── Планирование уведомления ──────────────────────────────────── */
  Future<void> _scheduleReminder(CalendarEvent event) async {
    final notifId = event.notificationId;
    if (notifId == null) return;

    // «Нет» (reminderMinutes == null) → 0 минут = уведомление РОВНО
    // в момент начала события. Раньше тут был ранний выход, поэтому
    // события без «напомнить за…» вообще не уведомляли.
    final minutes = event.reminderMinutes ?? 0;

    // Если у события задан собственный часовой пояс — пересчитываем время
    // начала в локальное (системное) представление, чтобы уведомление
    // сработало в правильный абсолютный момент.
    // start трактуется как «настенное» время в поясе события (Oe),
    // localStart = start + (Od - Oe).
    DateTime localStart = event.start;
    if (event.timeZoneOffset != null) {
      final deviceOffset = DateTime.now().timeZoneOffset.inMinutes;
      final diff = deviceOffset - event.timeZoneOffset!;
      localStart = event.start.add(Duration(minutes: diff));
    }
    final notifyTime = localStart.subtract(Duration(minutes: minutes));

    try {
      await NotificationService.scheduleNotification(
        int.parse(notifId),
        event.title,
        _reminderBody(minutes),
        notifyTime,
        repeatType: event.repeatType.index,
      );
    } catch (e) {
      debugPrint('NOTIFICATION ERROR: $e');
    }
  }

  String _reminderBody(int minutes) {
    if (minutes <= 0) return 'Событие начинается сейчас';
    if (minutes >= 1440) return 'Событие начнётся завтра';
    if (minutes >= 60) return 'Событие начнётся через час';
    return 'Событие начнётся через $minutes мин';
  }

  Future<void> loadHolidaysForCurrentCountry(int year) async {
    try {
      final String locale = Platform.localeName;
      final String countryCode = locale.contains('_') ? locale.split('_').last : locale;

      if (countryCode.isEmpty || countryCode.length != 2) return;

      final String settingKey = 'holidays_loaded_${countryCode}_$year';
      if (_settingsBox.get(settingKey, defaultValue: false) == true) return;

      final url = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> holidayList = jsonDecode(response.body);

        final existingTitles = _eventsBox.values
            .where((e) => e.start.year == year && e.category == EventCategory.holiday)
            .map((e) => e.title)
            .toSet();

        for (var holiday in holidayList) {
          final String title = holiday['localName'] ?? holiday['name'];
          final String dateStr = holiday['date'];
          final DateTime holidayDate = DateTime.parse(dateStr);

          if (existingTitles.contains(title)) continue;

          final holidayEvent = CalendarEvent(
            id: 'holiday_${countryCode}_${holidayDate.millisecondsSinceEpoch}',
            title: title,
            start: DateTime(holidayDate.year, holidayDate.month, holidayDate.day, 0, 0),
            end: DateTime(holidayDate.year, holidayDate.month, holidayDate.day, 23, 59),
            category: EventCategory.holiday,
            color: EventCategory.holiday.color.toARGB32(),
            repeatType: RepeatType.none,
          );

          await _eventsBox.put(holidayEvent.id, holidayEvent);
        }

        await _settingsBox.put(settingKey, true);
        notifyListeners();
        WidgetService.updateWidget();
      }
    } catch (e) {
      debugPrint('Holiday load error: $e');
    }
  }
}
