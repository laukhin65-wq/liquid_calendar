import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/location_analytics.dart';

class LocationAnalyticsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _allEvents =>
      _eventsBox.values.where((e) => e.category != EventCategory.holiday).toList();

  LocationAnalyticsModel calculate() {
    final locationMap = <String, _LocationAccumulator>{};

    for (final event in _allEvents) {
      if (event.location == null || event.location!.isEmpty) continue;

      final locationName = event.location!.trim();
      if (locationName.isEmpty) continue;

      final hours = event.end.difference(event.start).inMinutes / 60.0;

      locationMap.putIfAbsent(locationName, () => _LocationAccumulator());
      locationMap[locationName]!.visitCount++;
      locationMap[locationName]!.totalHours += hours;

      if (locationMap[locationName]!.lastVisitDate == null ||
          event.start.isAfter(locationMap[locationName]!.lastVisitDate!)) {
        locationMap[locationName]!.lastVisitDate = event.start;
      }
    }

    final locations = locationMap.entries.map((entry) {
      return LocationData(
        name: entry.key,
        visitCount: entry.value.visitCount,
        totalHours: entry.value.totalHours,
        lastVisitDate: entry.value.lastVisitDate,
      );
    }).toList();

    locations.sort((a, b) => b.totalHours.compareTo(a.totalHours));

    final uniqueLocations = locations.length;
    final totalVisits = locations.fold<int>(0, (sum, l) => sum + l.visitCount);

    final summaryText = _generateSummary(locations, uniqueLocations, totalVisits);

    return LocationAnalyticsModel(
      locations: locations,
      uniqueLocations: uniqueLocations,
      totalVisits: totalVisits,
      summaryText: summaryText,
    );
  }

  String _generateSummary(
      List<LocationData> locations, int uniqueLocations, int totalVisits) {
    final lines = <String>[];

    if (locations.isNotEmpty) {
      lines.add(
          'Наиболее посещаемое место: ${locations.first.name}.');
    }

    if (locations.length >= 2) {
      final longestStay = locations.first;
      lines.add(
          'Больше всего времени проведено в локации: ${longestStay.name}.');
    }

    if (uniqueLocations > 0) {
      lines.add('Всего уникальных мест: $uniqueLocations.');
    }

    return lines.isEmpty ? 'Нет данных о местах' : lines.join('\n');
  }
}

class _LocationAccumulator {
  int visitCount = 0;
  double totalHours = 0;
  DateTime? lastVisitDate;
}
