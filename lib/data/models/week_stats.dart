import 'calendar_event.dart';
import 'today_stats.dart';

class WeekStatsModel {
  final int totalEvents;
  final int totalTasks;
  final int completedTasks;
  final int meetings;
  final int uniqueContacts;
  final int uniqueLocations;
  final double totalHours;
  final double productivityPercentage;
  final CategoryTime? topCategory;
  final String? mostActiveDay;
  final List<String> contacts;
  final List<String> locations;
  final List<CalendarEvent> timeline;
  final String summaryText;

  const WeekStatsModel({
    required this.totalEvents,
    required this.totalTasks,
    required this.completedTasks,
    required this.meetings,
    required this.uniqueContacts,
    required this.uniqueLocations,
    required this.totalHours,
    required this.productivityPercentage,
    this.topCategory,
    this.mostActiveDay,
    required this.contacts,
    required this.locations,
    required this.timeline,
    required this.summaryText,
  });
}
