import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/event_category.dart';
import '../../screens/event_detail_screen.dart';
import '../../widgets/swipe_navigator.dart';

const double _hourHeight = 52;
const double _timeGutter = 44;

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return SwipePager(
      date: provider.selectedDate,
      unit: PeriodUnit.week,
      onDateChanged: provider.setDate,
      pageBuilder: (context, pageDate) => _WeekGrid(date: pageDate),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  final DateTime date;

  const _WeekGrid({required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final selected = provider.selectedDate;

    // Понедельник недели страницы
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));

    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      children: [
        // Заголовок недели с датами
        Row(
          children: [
            const SizedBox(width: _timeGutter),
            ...days.map((day) {
              final now = DateTime.now();
              final isToday = now.year == day.year &&
                  now.month == day.month &&
                  now.day == day.day;
              final isSelected = selected.year == day.year &&
                  selected.month == day.month &&
                  selected.day == day.day;
              final dayEvents = provider.filteredEvents
                  .where((e) => e.isVisibleOnDate(day))
                  .toList();
              final hasHoliday = dayEvents.any((e) => e.category == EventCategory.holiday);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    provider.setDate(day);
                    provider.setView(CalendarViewType.day);
                  },
                  child: Column(
                    children: [
                      Text(
                        _weekdayShort(day.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: Colors.red)
                              : null,
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: hasHoliday ? Color(0xFFEF5350) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),

        // Сетка времени
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: _hourHeight * 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ось времени
                  SizedBox(
                    width: _timeGutter,
                    child: Column(
                      children: List.generate(24, (hour) {
                        return SizedBox(
                          height: _hourHeight,
                          child: Transform.translate(
                            offset: const Offset(0, -6),
                            child: Text(
                              hour.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 7 колонок дней
                  ...days.map((day) {
                    return Expanded(
                      child: _DayColumn(day: day),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime day;

  const _DayColumn({required this.day});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final events =
        provider.filteredEvents.where((event) => event.isVisibleOnDate(day)).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Линии часов
          Column(
            children: List.generate(24, (hour) {
              return Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800, width: 0.5),
                  ),
                ),
              );
            }),
          ),

          // События
          ...events.map((event) {
            final start =
                event.start.isBefore(dayStart) ? dayStart : event.start;
            final end = event.end.isAfter(dayEnd) ? dayEnd : event.end;

            final startMinutes = start.difference(dayStart).inMinutes;
            var durationMinutes = end.difference(start).inMinutes;
            if (durationMinutes < 24) durationMinutes = 24;

            final color = _eventColor(event);

            return Positioned(
              top: startMinutes / 60 * _hourHeight,
              left: 1,
              right: 1,
              height: durationMinutes / 60 * _hourHeight,
              child: GestureDetector(
                onTap: () => _openEditDialog(context, provider, event),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border(left: BorderSide(color: color, width: 2)),
                  ),
                  child: Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      decoration: (event.category == EventCategory.task && event.isCompleted)
                          ? TextDecoration.lineThrough
                          : null,
                      color: (event.category == EventCategory.task && event.isCompleted)
                          ? Colors.grey
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

Future<void> _openEditDialog(
  BuildContext context,
  CalendarProvider provider,
  CalendarEvent event,
) async {
  Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)));
}

String _weekdayShort(int weekday) {
  const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  return names[(weekday - 1) % 7];
}

Color _eventColor(CalendarEvent event) {
  if (event.color != 0) return Color(event.color);
  return event.category.color;
}
