import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/category_analytics.dart';

class CategoryAnalyticsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _allEvents =>
      _eventsBox.values.where((e) => e.category != EventCategory.holiday).toList();

  CategoryAnalyticsModel calculate(AnalyticsPeriod period) {
    final now = DateTime.now();
    List<CalendarEvent> events;

    switch (period) {
      case AnalyticsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        events = _allEvents.where((e) => !e.start.isBefore(start)).toList();
        break;
      case AnalyticsPeriod.month:
        events = _allEvents.where((e) =>
            e.start.year == now.year && e.start.month == now.month).toList();
        break;
      case AnalyticsPeriod.allTime:
        events = _allEvents;
        break;
    }

    return _calculateFromEvents(events, period);
  }

  CategoryAnalyticsModel _calculateFromEvents(
      List<CalendarEvent> events, AnalyticsPeriod period) {
    final categoryMap = <EventCategory, _CategoryAccumulator>{};

    for (final cat in EventCategory.values) {
      if (cat != EventCategory.holiday) {
        categoryMap[cat] = _CategoryAccumulator();
      }
    }

    for (final event in events) {
      final cat = event.category;
      if (cat == EventCategory.holiday) continue;

      final hours = event.end.difference(event.start).inMinutes / 60.0;
      categoryMap[cat]!.eventCount++;
      categoryMap[cat]!.hours += hours;
    }

    double totalHours = 0;
    for (final acc in categoryMap.values) {
      totalHours += acc.hours;
    }

    final categories = <CategoryData>[];
    for (final entry in categoryMap.entries) {
      if (entry.value.eventCount > 0) {
        final percentage = totalHours > 0
            ? (entry.value.hours / totalHours * 100)
            : 0.0;
        categories.add(CategoryData(
          category: entry.key,
          eventCount: entry.value.eventCount,
          hours: entry.value.hours,
          percentage: percentage,
        ));
      }
    }

    categories.sort((a, b) => b.hours.compareTo(a.hours));

    CategoryData? largest;
    CategoryData? smallest;
    if (categories.isNotEmpty) {
      largest = categories.first;
      smallest = categories.last;
    }

    final summaryText = _generateSummary(categories, totalHours, period, largest, smallest);

    return CategoryAnalyticsModel(
      categories: categories,
      totalHours: totalHours,
      largestCategory: largest,
      smallestCategory: smallest,
      summaryText: summaryText,
    );
  }

  String _generateSummary(
    List<CategoryData> categories,
    double totalHours,
    AnalyticsPeriod period,
    CategoryData? largest,
    CategoryData? smallest,
  ) {
    if (categories.isEmpty) {
      return 'Нет данных за выбранный период';
    }

    final lines = <String>[];

    if (largest != null && largest.percentage > 0) {
      lines.add('Большая часть времени была посвящена '
          '${_categoryName(largest.category)} (${largest.percentage.toInt()}%).');
    }

    if (smallest != null && smallest != largest && smallest.percentage > 0) {
      lines.add('На ${_categoryName(smallest.category)} ушло '
          '${smallest.percentage.toInt()}% времени.');
    }

    if (categories.length >= 2) {
      final first = categories[0];
      final second = categories[1];
      if (first.percentage > 0 && second.percentage > 0) {
        lines.add('Баланс между ${_categoryName(first.category)} и '
            '${_categoryName(second.category)} составляет '
            '${first.percentage.toInt()}% к ${second.percentage.toInt()}%.');
      }
    }

    return lines.join('\n');
  }

  String _categoryName(EventCategory cat) {
    switch (cat) {
      case EventCategory.work:
        return 'работе';
      case EventCategory.sport:
        return 'спорту';
      case EventCategory.study:
        return 'учёбе';
      case EventCategory.personal:
        return 'личным делам';
      case EventCategory.important:
        return 'важным делам';
      case EventCategory.task:
        return 'задачам';
      case EventCategory.birthday:
        return 'дням рождения';
      case EventCategory.holiday:
        return 'праздникам';
    }
  }
}

class _CategoryAccumulator {
  int eventCount = 0;
  double hours = 0;
}
