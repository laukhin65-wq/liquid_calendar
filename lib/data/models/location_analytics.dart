class LocationAnalyticsModel {
  final List<LocationData> locations;
  final int uniqueLocations;
  final int totalVisits;
  final String summaryText;

  const LocationAnalyticsModel({
    required this.locations,
    required this.uniqueLocations,
    required this.totalVisits,
    required this.summaryText,
  });
}

class LocationData {
  final String name;
  final int visitCount;
  final double totalHours;
  final DateTime? lastVisitDate;

  const LocationData({
    required this.name,
    required this.visitCount,
    required this.totalHours,
    this.lastVisitDate,
  });
}
