import 'package:hive/hive.dart';
import '../models/calendar_event.dart';

class EventRepository {
  static const String boxName = 'events';

  Future<Box<CalendarEvent>> openBox() async {
    return await Hive.openBox<CalendarEvent>(boxName);
  }

  Box<CalendarEvent> get box {
    return Hive.box<CalendarEvent>(boxName);
  }

  List<CalendarEvent> getAllEvents() {
    return box.values.toList();
  }

  Future<void> addEvent(CalendarEvent event) async {
    await box.put(event.id, event);
  }

  Future<void> deleteEvent(String id) async {
    await box.delete(id);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await box.put(event.id, event);
  }
}