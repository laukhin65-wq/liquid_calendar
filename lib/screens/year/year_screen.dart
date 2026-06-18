import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../data/models/event_category.dart';
import '../../widgets/swipe_navigator.dart';
import '../../widgets/zoom_transition_switcher.dart';

/// Годовой вид: 12 мини-месяцев. Заголовок года — в [CalendarHeader].
/// Перелистывание лет — пальцем (страница тянется за пальцем).
class YearScreen extends StatelessWidget {
  const YearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return SwipePager(
      date: provider.selectedDate,
      unit: PeriodUnit.year,
      onDateChanged: provider.setDate,
      pageBuilder: (context, pageDate) => _YearGrid(year: pageDate.year),
    );
  }
}

class _YearGrid extends StatelessWidget {
  final int year;

  const _YearGrid({required this.year});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.74,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return _MiniMonth(year: year, month: index + 1);
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final int year;
  final int month;

  const _MiniMonth({required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final now = DateTime.now();

    final firstWeekday = DateTime(year, month, 1).weekday;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstWeekday - 1;
    final isCurrentMonth = now.year == year && now.month == month;

    final datesWithEvents = <int>{};
    final datesWithHolidays = <int>{};
    for (final event in provider.filteredEvents) {
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        if (event.isVisibleOnDate(date)) {
          datesWithEvents.add(day);
          if (event.category == EventCategory.holiday) {
            datesWithHolidays.add(day);
          }
        }
      }
    }

    return GestureDetector(
      onTap: () {
        setZoomAnchor(context); // запомнить точку тапа для zoom-наезда
        provider.setDate(DateTime(year, month, 1));
        provider.setView(CalendarViewType.month);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthName(month),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isCurrentMonth ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: const ['п', 'в', 'с', 'ч', 'п', 'с', 'в']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Column(
              children: List.generate(6, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (col) {
                      final dayNumber = row * 7 + col - startOffset + 1;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const Expanded(child: SizedBox());
                      }

                      final isToday = isCurrentMonth && now.day == dayNumber;
                      final hasEvents = datesWithEvents.contains(dayNumber);
                      final hasHoliday = datesWithHolidays.contains(dayNumber);
                      final isWeekend = col >= 5;

                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.red : null,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isToday
                                        ? Colors.white
                                        : hasHoliday
                                            ? Color(0xFFEF5350)
                                            : isWeekend
                                                ? Colors.red
                                                : null,
                                  ),
                                ),
                                if (hasEvents && !isToday)
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const names = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
  return names[(month - 1) % 12];
}
