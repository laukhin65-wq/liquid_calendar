import 'calendar_event.dart';

class TodayStatsModel {
  final int totalEvents;
  final int totalTasks;
  final int completedTasks;
  final int meetings;
  final int uniqueContacts;
  final int uniqueLocations;
  final double totalHours;
  final double productivityPercentage;
  final CategoryTime? topCategory;
  final List<String> contacts;
  final List<String> locations;
  final List<CalendarEvent> timeline;
  final String summaryText;

  const TodayStatsModel({
    required this.totalEvents,
    required this.totalTasks,
    required this.completedTasks,
    required this.meetings,
    required this.uniqueContacts,
    required this.uniqueLocations,
    required this.totalHours,
    required this.productivityPercentage,
    this.topCategory,
    required this.contacts,
    required this.locations,
    required this.timeline,
    required this.summaryText,
  });

  String contactName(String contact) {
    if (contact.contains(' | ')) {
      return contact.split(' | ').first;
    }
    return contact;
  }

  String contactPhone(String contact) {
    if (contact.contains(' | ')) {
      return contact.split(' | ').last;
    }
    return '';
  }
}

class CategoryTime {
  final String category;
  final double hours;

  const CategoryTime({
    required this.category,
    required this.hours,
  });
}
