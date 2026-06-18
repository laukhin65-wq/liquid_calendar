import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/week_stats.dart';
import '../data/models/today_stats.dart';

class WeekStatsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _weekEvents {
    final now = DateTime.now();
    final weekday = now.weekday;
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _eventsBox.values.where((e) {
      return !e.start.isBefore(weekStart) && e.start.isBefore(weekEnd);
    }).toList();
  }

  WeekStatsModel calculate() {
    final events = _weekEvents;

    final totalEvents = events.length;

    final tasks = events.where((e) => e.category == EventCategory.task).toList();
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((e) => e.isCompleted).length;

    final meetings = events.where((e) => e.isMeeting).length;

    final uniqueContacts = <String>{};
    for (final event in events) {
      if (event.contacts != null) {
        for (final c in event.contacts!) {
          uniqueContacts.add(c);
        }
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

    final productivityPercentage = totalTasks > 0
        ? (completedTasks / totalTasks * 100)
        : 0.0;

    final categoryHours = <String, double>{};
    for (final event in events) {
      final cat = event.category;
      final hours = event.end.difference(event.start).inMinutes / 60.0;
      categoryHours[cat.label] = (categoryHours[cat.label] ?? 0) + hours;
    }

    CategoryTime? topCategory;
    if (categoryHours.isNotEmpty) {
      final top = categoryHours.entries.reduce((a, b) => a.value >= b.value ? a : b);
      topCategory = CategoryTime(category: top.key, hours: top.value);
    }

    final contacts = uniqueContacts.toList();
    final locations = uniqueLocations.toList();

    final timeline = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.start.compareTo(b.start));

    final dayCounts = <int, int>{};
    for (final event in events) {
      final weekday = event.start.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    String? mostActiveDay;
    if (dayCounts.isNotEmpty) {
      final maxEntry = dayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      mostActiveDay = _weekdayName(maxEntry.key);
    }

    final summaryText = _generateSummary(
      totalEvents: totalEvents,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      meetings: meetings,
      totalHours: totalHours,
      topCategory: topCategory,
    );

    return WeekStatsModel(
      totalEvents: totalEvents,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      meetings: meetings,
      uniqueContacts: uniqueContacts.length,
      uniqueLocations: uniqueLocations.length,
      totalHours: totalHours,
      productivityPercentage: productivityPercentage,
      topCategory: topCategory,
      mostActiveDay: mostActiveDay,
      contacts: contacts,
      locations: locations,
      timeline: timeline,
      summaryText: summaryText,
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

  String _generateSummary({
    required int totalEvents,
    required int totalTasks,
    required int completedTasks,
    required int meetings,
    required double totalHours,
    CategoryTime? topCategory,
  }) {
    final lines = <String>[];

    if (totalHours > 0) {
      final hours = totalHours.toStringAsFixed(totalHours == totalHours.roundToDouble() ? 0 : 1);
      lines.add('На этой неделе запланировано $hours часов активности.');
    }

    if (meetings > 0) {
      String meetingWord;
      if (meetings == 1) {
        meetingWord = 'встреча';
      } else if (meetings >= 2 && meetings <= 4) {
        meetingWord = 'встречи';
      } else {
        meetingWord = 'встреч';
      }
      lines.add('На этой неделе запланировано $meetingWord.');
    }

    if (topCategory != null) {
      lines.add('Основная категория недели — ${topCategory.category}.');
    }

    if (lines.isEmpty) {
      return 'На этой неделе пока нет событий.';
    }

    return lines.join('\n');
  }
}
