import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../data/models/calendar_event.dart';
import '../data/models/event_category.dart';
import '../screens/event_detail_screen.dart';
import '../models/schedule_item.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.black45;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    final allEvents = provider.filteredEvents;
    final items = ScheduleBuilder.build(allEvents);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Расписание', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      ),
      body: items.isEmpty
          ? Center(child: Text('Нет событий', style: TextStyle(color: subtextColor, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return switch (item) {
                  MonthHeaderItem() => _MonthHeader(title: item.title, textColor: textColor),
                  DayHeaderItem() => _DayHeader(date: item.date, isToday: item.isToday, textColor: textColor),
                  EventItem() => _EventCard(event: item.event, cardColor: cardColor, textColor: textColor, subtextColor: subtextColor, context: context),
                  FreeRangeItem() => _FreeRange(from: item.from, to: item.to, subtextColor: subtextColor),
                };
              },
            ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _MonthHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final Color textColor;
  const _DayHeader({required this.date, required this.isToday, required this.textColor});

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[(date.weekday - 1) % 7];
    final month = _months[date.month - 1];

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)),
              child: const Text('Сегодня', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          if (isToday) const SizedBox(width: 6),
          Text('$weekday, ${date.day} $month', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final BuildContext context;

  const _EventCard({
    required this.event,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final cat = event.category;
    final eventColor = event.color != 0 ? Color(event.color) : cat.color;
    final isTask = cat == EventCategory.task;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          dense: true,
          leading: Container(width: 3, height: 32, decoration: BoxDecoration(color: eventColor, borderRadius: BorderRadius.circular(2))),
          title: Text(event.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, decoration: (isTask && event.isCompleted) ? TextDecoration.lineThrough : null)),
          subtitle: Text(
            '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')} – ${event.end.hour.toString().padLeft(2, '0')}:${event.end.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 11, color: subtextColor),
          ),
          trailing: Icon(Icons.chevron_right, color: subtextColor, size: 18),
        ),
      ),
    );
  }
}

class _FreeRange extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final Color subtextColor;
  const _FreeRange({required this.from, required this.to, required this.subtextColor});

  static const _months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final days = to.difference(from).inDays + 1;

    String label;
    if (days == 1) {
      label = 'Свободный день: ${_fmt(from)}';
    } else {
      label = '${_fmt(from)} – ${_fmt(to)} свободны';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: subtextColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: subtextColor.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 16, color: subtextColor.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: subtextColor, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}
