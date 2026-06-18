class PeopleAnalyticsModel {
  final List<ContactData> contacts;
  final int uniqueContacts;
  final int totalMeetings;
  final String summaryText;

  const PeopleAnalyticsModel({
    required this.contacts,
    required this.uniqueContacts,
    required this.totalMeetings,
    required this.summaryText,
  });
}

class ContactData {
  final String name;
  final int meetingCount;
  final double totalHours;
  final DateTime? lastMeetingDate;

  const ContactData({
    required this.name,
    required this.meetingCount,
    required this.totalHours,
    this.lastMeetingDate,
  });
}
