import '../../data/models/event_category.dart';

class CategoryAnalyticsModel {
  final List<CategoryData> categories;
  final double totalHours;
  final CategoryData? largestCategory;
  final CategoryData? smallestCategory;
  final String summaryText;

  const CategoryAnalyticsModel({
    required this.categories,
    required this.totalHours,
    this.largestCategory,
    this.smallestCategory,
    required this.summaryText,
  });
}

class CategoryData {
  final EventCategory category;
  final int eventCount;
  final double hours;
  final double percentage;

  const CategoryData({
    required this.category,
    required this.eventCount,
    required this.hours,
    required this.percentage,
  });
}

enum AnalyticsPeriod {
  week,
  month,
  allTime,
}

extension AnalyticsPeriodExtension on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.week:
        return 'Неделя';
      case AnalyticsPeriod.month:
        return 'Месяц';
      case AnalyticsPeriod.allTime:
        return 'Всё время';
    }
  }
}
