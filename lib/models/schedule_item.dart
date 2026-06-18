import '../data/models/calendar_event.dart';

sealed class ScheduleItem {}

class MonthHeaderItem extends ScheduleItem {
  final String title;
  MonthHeaderItem(this.title);
}

class DayHeaderItem extends ScheduleItem {
  final DateTime date;
  final bool isToday;
  DayHeaderItem(this.date, {this.isToday = false});
}

class EventItem extends ScheduleItem {
  final CalendarEvent event;
  EventItem(this.event);
}

class FreeRangeItem extends ScheduleItem {
  final DateTime from;
  final DateTime to;
  FreeRangeItem(this.from, this.to);
}

class ScheduleBuilder {
  static const _ruMonths = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static List<ScheduleItem> build(List<CalendarEvent> events) {
    if (events.isEmpty) return [];

    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.start.compareTo(b.start));

    final minDate = sorted.first.start;
    final maxDate = sorted.last.end;

    final items = <ScheduleItem>[];
    var currentMonth = -1;
    var day = _mondayOfWeek(minDate);
    final sundayEnd = _sundayOfWeek(maxDate);

    while (!day.isAfter(sundayEnd)) {
      final weekMonday = _mondayOfWeek(day);
      final weekSunday = _sundayOfWeek(day);

      for (int d = 0; d < 7; d++) {
        final currentDay = weekMonday.add(Duration(days: d));
        if (currentDay.isAfter(sundayEnd)) break;

        final currentDayMonth = currentDay.month - 1;
        if (currentDayMonth != currentMonth) {
          currentMonth = currentDayMonth;
          items.add(MonthHeaderItem('${_ruMonths[currentDayMonth]} ${currentDay.year}'));
        }

        final dayEvents = sorted.where((e) => e.isVisibleOnDate(currentDay)).toList();

        if (dayEvents.isNotEmpty) {
          items.add(DayHeaderItem(currentDay, isToday: _isToday(currentDay)));
          for (final event in dayEvents) {
            items.add(EventItem(event));
          }
          continue;
        }

        var freeEnd = currentDay;
        while (true) {
          final nextDay = freeEnd.add(const Duration(days: 1));
          if (nextDay.isAfter(weekSunday)) break;
          if (nextDay.month != freeEnd.month) break;
          final nextEvents = sorted.where((e) => e.isVisibleOnDate(nextDay)).toList();
          if (nextEvents.isNotEmpty) break;
          freeEnd = nextDay;
        }

        items.add(FreeRangeItem(currentDay, freeEnd));
        d += freeEnd.difference(currentDay).inDays;
      }

      day = weekSunday.add(const Duration(days: 1));
    }

    return items;
  }

  static DateTime _mondayOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  static DateTime _sundayOfWeek(DateTime date) =>
      date.add(Duration(days: 7 - date.weekday));

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
