import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/calendar_event.dart';
import '../screens/add_event_screen.dart';
import '../screens/event_detail_screen.dart';

class WidgetActionService {
  WidgetActionService._();

  static void handleAction(
    String action,
    String eventId, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    try {
      if (action == 'OPEN_EVENT' && eventId.isNotEmpty) {
        final eventsBox = Hive.box<CalendarEvent>('events');
        final event = eventsBox.get(eventId);
        if (event != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: eventId),
            ),
          );
        }
      } else if (action == 'ADD_EVENT' || action == 'ADD_TASK') {
        final isTask = action == 'ADD_TASK';
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AddEventScreen(initialTabIndex: isTask ? 1 : 0),
          ),
        );
      }
    } catch (e) {
      debugPrint('Widget action error: $e');
    }
  }
}
