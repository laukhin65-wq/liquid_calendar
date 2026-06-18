class LifeStatistics {
  final AllTimeStats allTime;
  final ProductivityStats productivity;
  final MonthStats currentMonth;
  final MonthSummary monthSummary;

  const LifeStatistics({
    required this.allTime,
    required this.productivity,
    required this.currentMonth,
    required this.monthSummary,
  });
}

class AllTimeStats {
  final int totalEvents;
  final int totalTasks;
  final int completedTasks;
  final int uniqueContacts;
  final int uniqueLocations;
  final int totalAttachments;
  final double totalHours;

  const AllTimeStats({
    required this.totalEvents,
    required this.totalTasks,
    required this.completedTasks,
    required this.uniqueContacts,
    required this.uniqueLocations,
    required this.totalAttachments,
    required this.totalHours,
  });
}

class ProductivityStats {
  final int createdTasks;
  final int completedTasks;
  final double percentage;

  const ProductivityStats({
    required this.createdTasks,
    required this.completedTasks,
    required this.percentage,
  });
}

class MonthStats {
  final int events;
  final int completedTasks;
  final int uniqueContacts;
  final int uniqueLocations;
  final double totalHours;

  const MonthStats({
    required this.events,
    required this.completedTasks,
    required this.uniqueContacts,
    required this.uniqueLocations,
    required this.totalHours,
  });
}

class MonthSummary {
  final int events;
  final int completedTasks;
  final int locations;
  final int meetings;
  final String? mostActiveDay;

  const MonthSummary({
    required this.events,
    required this.completedTasks,
    required this.locations,
    required this.meetings,
    this.mostActiveDay,
  });
}
