import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calendar_provider.dart';
import '../data/models/event_category.dart';
import '../screens/event_detail_screen.dart';
import 'glass.dart';

class DayEventsList extends StatelessWidget {
  const DayEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final glass = isGlassTheme(context);
    final selectedDate = provider.selectedDate;

    final events = provider.filteredEvents
        .where((event) => event.isVisibleOnDate(selectedDate))
        .toList();

    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('На этот день событий нет'),
      );
    }

    final isTask = events.any((e) =>
        e.category == EventCategory.task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            isTask ? 'Задачи' : 'События',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...events.map((event) {
          final eventColor = event.color != 0
              ? Color(event.color)
              : _getCategoryColor(event.category);
          final cat = event.category;
          final isTaskEvent = cat == EventCategory.task;
          final completed = event.isCompleted;

          final tile = ListTile(
            leading: Icon(
              isTaskEvent
                  ? (completed ? Icons.check_circle : Icons.radio_button_unchecked)
                  : Icons.event,
              color: completed ? const Color(0xFF34C759) : eventColor,
            ),
            title: Text(
              event.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')} - '
                  '${event.end.hour.toString().padLeft(2, '0')}:${event.end.minute.toString().padLeft(2, '0')}',
              style: completed ? const TextStyle(color: Colors.grey) : null,
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
          );

          if (glass) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GlassContainer(
                blur: 10,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: tile,
              ),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: tile,
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(EventCategory category) {
    return category.color;
  }
}
