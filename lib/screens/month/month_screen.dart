import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../data/models/calendar_event.dart';
import '../../widgets/swipe_navigator.dart';
import '../../widgets/zoom_transition_switcher.dart';
import '../../data/models/event_category.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return SwipePager(
      date: provider.selectedDate,
      unit: PeriodUnit.month,
      onDateChanged: provider.setDate,
      pageBuilder: (context, pageDate) => _MonthGrid(date: pageDate),
    );
  }
}

/// Сетка одного месяца (для даты [date]).
class _MonthGrid extends StatelessWidget {
  final DateTime date;

  const _MonthGrid({required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final firstWeekday = DateTime(date.year, date.month, 1).weekday;
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final startOffset = firstWeekday - 1;

    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final event in provider.filteredEvents) {
      for (int day = 1; day <= daysInMonth; day++) {
        final cellDate = DateTime(date.year, date.month, day);
        if (event.isVisibleOnDate(cellDate)) {
          eventsByDay.putIfAbsent(day, () => []).add(event);
        }
      }
    }
    for (final entry in eventsByDay.entries) {
      entry.value.sort((a, b) => a.start.compareTo(b.start));
    }

    return Column(
      children: [
        const _WeekDaysHeader(),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minRowHeight = 72.0;
              final fitRowHeight = constraints.maxHeight / 6;
              final rowHeight =
                  fitRowHeight < minRowHeight ? minRowHeight : fitRowHeight;

              final grid = Column(
                children: List.generate(6, (row) {
                  return SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: List.generate(7, (col) {
                        final dayNumber = row * 7 + col - startOffset + 1;

                        // Дни соседних месяцев не показываем.
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const Expanded(child: SizedBox());
                        }

                        final cellDate =
                            DateTime(date.year, date.month, dayNumber);

                        return Expanded(
                          child: _DayCell(
                            date: cellDate,
                            events: eventsByDay[dayNumber] ?? const [],
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );

              // Если 6 строк не помещаются (альбомная ориентация) — скроллим.
              if (rowHeight * 6 > constraints.maxHeight) {
                return SingleChildScrollView(child: grid);
              }
              return grid;
            },
          ),
        ),
      ],
    );
  }
}

class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['п', 'в', 'с', 'ч', 'п', 'с', 'в'];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: List.generate(7, (i) {
        final isWeekend = i >= 5;
        return Expanded(
          child: Center(
            child: Text(
              days[i],
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: isWeekend ? 0.45 : 0.65),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;

  const _DayCell({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final isToday = _sameDay(now, date);
    final isSelected = _sameDay(provider.selectedDate, date);
    final isWeekend = date.weekday >= 6;
    final hasHoliday = events.any((e) => e.category == EventCategory.holiday);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isSelected) {
          // Второй тап — переход на экран день.
          setZoomAnchor(context);
          provider.setView(CalendarViewType.day);
        } else {
          // Первый тап — выделение даты.
          provider.setDate(date);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.onSurface.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.red
                      : isSelected
                          ? Colors.grey
                          : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isToday || isSelected
                        ? Colors.white
                        : hasHoliday
                            ? Color(0xFFEF5350)
                            : isWeekend
                                ? Colors.red
                                : scheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final event in events.take(3)) _chip(context, event),
                    if (events.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 1),
                        child: Text(
                          '+${events.length - 3}',
                          style: TextStyle(
                            fontSize: 8,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _chip(BuildContext context, CalendarEvent event) {
final color = _eventColor(event);
final onSurface = Theme.of(context).colorScheme.onSurface;

return Padding(
padding: const EdgeInsets.only(
left: 2,
right: 2,
bottom: 2,
),
child: Row(
children: [
Container(
width: 6,
height: 6,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
),
),

const SizedBox(width: 4),

Expanded(
child: Text(
event.title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 9,
color: (event.category == EventCategory.task && event.isCompleted)
    ? Colors.grey
    : onSurface,
decoration: (event.category == EventCategory.task && event.isCompleted)
    ? TextDecoration.lineThrough
    : null,
),
),
),
],
),
);
}
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color _eventColor(CalendarEvent event) {
  if (event.color != 0) {
    return Color(event.color);
  }
  return event.category.color;
}
