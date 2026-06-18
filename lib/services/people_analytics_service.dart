import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../data/models/people_analytics.dart';

class PeopleAnalyticsService {
  final Box<CalendarEvent> _eventsBox = Hive.box<CalendarEvent>('events');

  List<CalendarEvent> get _allEvents =>
      _eventsBox.values.where((e) => e.category != EventCategory.holiday).toList();

  PeopleAnalyticsModel calculate() {
    final contactMap = <String, _ContactAccumulator>{};

    for (final event in _allEvents) {
      if (event.contacts == null || event.contacts!.isEmpty) continue;

      final hours = event.end.difference(event.start).inMinutes / 60.0;

      for (final contactName in event.contacts!) {
        final name = contactName.trim();
        if (name.isEmpty) continue;

        contactMap.putIfAbsent(name, () => _ContactAccumulator());
        contactMap[name]!.meetingCount++;
        contactMap[name]!.totalHours += hours;

        if (contactMap[name]!.lastMeetingDate == null ||
            event.start.isAfter(contactMap[name]!.lastMeetingDate!)) {
          contactMap[name]!.lastMeetingDate = event.start;
        }
      }
    }

    final contacts = contactMap.entries.map((entry) {
      return ContactData(
        name: entry.key,
        meetingCount: entry.value.meetingCount,
        totalHours: entry.value.totalHours,
        lastMeetingDate: entry.value.lastMeetingDate,
      );
    }).toList();

    contacts.sort((a, b) => b.meetingCount.compareTo(a.meetingCount));

    final uniqueContacts = contacts.length;
    final totalMeetings = contacts.fold<int>(0, (sum, c) => sum + c.meetingCount);

    final summaryText = _generateSummary(contacts, uniqueContacts, totalMeetings);

    return PeopleAnalyticsModel(
      contacts: contacts,
      uniqueContacts: uniqueContacts,
      totalMeetings: totalMeetings,
      summaryText: summaryText,
    );
  }

  String _generateSummary(
      List<ContactData> contacts, int uniqueContacts, int totalMeetings) {
    final lines = <String>[];

    if (contacts.isNotEmpty) {
      lines.add(
          'Чаще всего вы взаимодействовали с ${contacts.first.name}.');
    }

    if (uniqueContacts > 0) {
      lines.add('Всего уникальных контактов: $uniqueContacts.');
    }

    if (totalMeetings > 0) {
      lines.add('Всего встреч с людьми: $totalMeetings.');
    }

    return lines.isEmpty ? 'Нет данных о контактах' : lines.join('\n');
  }
}

class _ContactAccumulator {
  int meetingCount = 0;
  double totalHours = 0;
  DateTime? lastMeetingDate;
}
