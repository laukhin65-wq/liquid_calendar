import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/today_stats.dart';

class TodayStatsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _todayEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _eventsBox.values.where((e) => e.isVisibleOnDate(today)).toList();
  }

  TodayStatsModel calculate() {
    final events = _todayEvents;

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

    final summaryText = _generateSummary(
      totalEvents: totalEvents,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      meetings: meetings,
      totalHours: totalHours,
      topCategory: topCategory,
    );

    return TodayStatsModel(
      totalEvents: totalEvents,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      meetings: meetings,
      uniqueContacts: uniqueContacts.length,
      uniqueLocations: uniqueLocations.length,
      totalHours: totalHours,
      productivityPercentage: productivityPercentage,
      topCategory: topCategory,
      contacts: contacts,
      locations: locations,
      timeline: timeline,
      summaryText: summaryText,
    );
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
      lines.add('Сегодня запланировано $hours часов активности.');
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
      lines.add('Сегодня запланировано $meetingWord.');
    }

    if (topCategory != null) {
      lines.add('Основная категория дня — ${topCategory.category}.');
    }

    if (lines.isEmpty) {
      return 'Сегодня пока нет событий.';
    }

    return lines.join('\n');
  }
}
