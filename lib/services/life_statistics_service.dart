import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/life_statistics.dart';

class LifeStatisticsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _allEvents =>
      _eventsBox.values.where((e) => e.category != EventCategory.holiday).toList();

  List<CalendarEvent> getEventsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _eventsBox.values.where((e) => e.isVisibleOnDate(targetDate)).toList();
  }

  List<CalendarEvent> getEventsInRange(DateTime start, DateTime end) {
    return _eventsBox.values.where((e) =>
        !e.start.isBefore(start) && e.start.isBefore(end)).toList();
  }

  LifeStatistics calculate() {
    final allTime = _calculateAllTime();
    final productivity = _calculateProductivity();
    final currentMonth = _calculateMonth();
    final monthSummary = _calculateMonthSummary();

    return LifeStatistics(
      allTime: allTime,
      productivity: productivity,
      currentMonth: currentMonth,
      monthSummary: monthSummary,
    );
  }

  AllTimeStats _calculateAllTime() {
    final events = _allEvents;

    final totalEvents = events.length;

    final totalTasks = events
        .where((e) => e.category == EventCategory.task)
        .length;

    final completedTasks = events
        .where((e) => e.category == EventCategory.task && e.isCompleted)
        .length;

    final uniqueContacts = <String>{};
    for (final event in events) {
      if (event.contacts != null) {
        uniqueContacts.addAll(event.contacts!);
      }
    }

    final uniqueLocations = <String>{};
    for (final event in events) {
      if (event.location != null && event.location!.isNotEmpty) {
        uniqueLocations.add(event.location!);
      }
    }

    int totalAttachments = 0;
    for (final event in events) {
      if (event.attachments != null) {
        totalAttachments += event.attachments!.length;
      }
    }

    double totalHours = 0;
    for (final event in events) {
      totalHours += event.end.difference(event.start).inMinutes / 60.0;
    }

    return AllTimeStats(
      totalEvents: totalEvents,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      uniqueContacts: uniqueContacts.length,
      uniqueLocations: uniqueLocations.length,
      totalAttachments: totalAttachments,
      totalHours: totalHours,
    );
  }

  ProductivityStats _calculateProductivity() {
    final tasks = _allEvents
        .where((e) => e.category == EventCategory.task)
        .toList();

    final createdTasks = tasks.length;
    final completedTasks = tasks.where((e) => e.isCompleted).length;
    final percentage = createdTasks > 0 ? (completedTasks / createdTasks * 100) : 0.0;

    return ProductivityStats(
      createdTasks: createdTasks,
      completedTasks: completedTasks,
      percentage: percentage,
    );
  }

  MonthStats _calculateMonth() {
    final now = DateTime.now();
    final events = _allEvents.where((e) =>
        e.start.year == now.year && e.start.month == now.month).toList();

    final completedTasks = events
        .where((e) => e.category == EventCategory.task && e.isCompleted)
        .length;

    final uniqueContacts = <String>{};
    for (final event in events) {
      if (event.contacts != null) {
        uniqueContacts.addAll(event.contacts!);
      }
    }

    final uniqueLocations = <String>{};
    for (final event in events) {
      if (event.location != null && event.location!.isNotEmpty) {
        uniqueLocations.add(event.location!);
      }
    }

    double totalHours = 0;
    for (final event in events) {
      totalHours += event.end.difference(event.start).inMinutes / 60.0;
    }

    return MonthStats(
      events: events.length,
      completedTasks: completedTasks,
      uniqueContacts: uniqueContacts.length,
      uniqueLocations: uniqueLocations.length,
      totalHours: totalHours,
    );
  }

  MonthSummary _calculateMonthSummary() {
    final now = DateTime.now();
    final events = _allEvents.where((e) =>
        e.start.year == now.year && e.start.month == now.month).toList();

    final completedTasks = events
        .where((e) => e.category == EventCategory.task && e.isCompleted)
        .length;

    final uniqueLocations = <String>{};
    for (final event in events) {
      if (event.location != null && event.location!.isNotEmpty) {
        uniqueLocations.add(event.location!);
      }
    }

    final meetings = events
        .where((e) => e.isMeeting)
        .length;

    final dayCounts = <int, int>{};
    for (final event in events) {
      final weekday = event.start.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    String? mostActiveDay;
    if (dayCounts.isNotEmpty) {
      final maxEntry = dayCounts.entries.reduce(
          (a, b) => a.value >= b.value ? a : b);
      mostActiveDay = _weekdayName(maxEntry.key);
    }

    return MonthSummary(
      events: events.length,
      completedTasks: completedTasks,
      locations: uniqueLocations.length,
      meetings: meetings,
      mostActiveDay: mostActiveDay,
    );
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Понедельник';
      case 2: return 'Вторник';
      case 3: return 'Среда';
      case 4: return 'Четверг';
      case 5: return 'Пятница';
      case 6: return 'Суббота';
      case 7: return 'Воскресенье';
      default: return '';
    }
  }
}
