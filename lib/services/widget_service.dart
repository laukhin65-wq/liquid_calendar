import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';

class WidgetService {
  static const _channel = MethodChannel('com.example.liquid_calendar/widget');

  static Future<void> updateWidget({String theme = 'system'}) async {
    try {
      final eventsBox = Hive.box<CalendarEvent>('events');
      final now = DateTime.now();

      final todayEvents = eventsBox.values
          .where((e) => e.isVisibleOnDate(now))
          .map((e) {
        final cat = e.category;
        final eventColor = e.color != 0 ? e.color : cat.color.toARGB32();
        return {
          'id': e.id,
          'title': e.title,
          'time':
              '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}',
          'color': eventColor,
          'isTask': cat == EventCategory.task,
          'isCompleted': e.isCompleted,
        };
      }).toList();

      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final monthEventsDetail = <Map<String, dynamic>>[];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(now.year, now.month, day);
        final dayEvents = eventsBox.values
            .where((e) => e.isVisibleOnDate(date))
            .toList();
        if (dayEvents.isNotEmpty) {
          for (final event in dayEvents) {
            final cat = event.category;
            monthEventsDetail.add({
              'day': day,
              'category': event.category.index,
              'title': event.title,
              'color': event.color != 0 ? event.color : cat.color.toARGB32(),
            });
          }
        }
      }

      await _channel.invokeMethod('updateWidget', {
        'dayEvents': jsonEncode(todayEvents),
        'monthEventsDetail': jsonEncode(monthEventsDetail),
        'theme': theme,
      });
    } on PlatformException catch (_) {}
  }
}
