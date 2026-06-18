import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';

void main() {
  test('CalendarEvent.isMeeting returns true when contacts exist', () {
    final event = CalendarEvent(
      id: "1",
      title: "Meeting",
      start: DateTime(2025, 1, 15),
      end: DateTime(2025, 1, 15, 1),
      color: 0,
      repeatType: RepeatType.none,
      category: EventCategory.work,
      contacts: ["Alice", "Bob"],
    );
    expect(event.isMeeting, isTrue);
  });

  test('CalendarEvent.isMeeting returns false when no contacts', () {
    final event = CalendarEvent(
      id: "1",
      title: "Solo",
      start: DateTime(2025, 1, 15),
      end: DateTime(2025, 1, 15, 1),
      color: 0,
      repeatType: RepeatType.none,
      category: EventCategory.personal,
    );
    expect(event.isMeeting, isFalse);
  });

  test('CalendarEvent.isMeeting returns false with empty contacts', () {
    final event = CalendarEvent(
      id: "1",
      title: "Empty",
      start: DateTime(2025, 1, 15),
      end: DateTime(2025, 1, 15, 1),
      color: 0,
      repeatType: RepeatType.none,
      category: EventCategory.personal,
      contacts: [],
    );
    expect(event.isMeeting, isFalse);
  });
}
