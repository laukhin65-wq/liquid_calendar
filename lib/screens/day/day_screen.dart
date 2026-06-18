import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/event_category.dart';
import '../../data/models/repeat_type.dart';
import '../../screens/event_detail_screen.dart';

const double _hourHeight = 64;
const double _timeGutter = 56;
const double _leftPad = 8;
const double _rightPad = 8;
const double _colGap = 4;
const int _minDurationMin = 30;

/// Расписание выбранного дня (таймлайн). Полоса недели и кнопка «назад»
/// находятся в [CalendarHeader]. День меняется тапом по дате в полосе недели,
/// свайпом по таймлайну день НЕ переключается.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    // ЗАЩИТА: Если виджет уже уничтожен (пользователь ушёл с экрана), прерываем скролл
    if (!mounted) return;

    final now = DateTime.now();
    final offset = ((now.hour * 60 + now.minute) / 60) * _hourHeight - 250;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0, double.infinity),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final date = provider.selectedDate;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final now = DateTime.now();
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.onSurface.withValues(alpha: 0.12);
    final mutedText = scheme.onSurface.withValues(alpha: 0.6);

    // 1. Готовим «уложенные» события дня (с учётом повторов и обрезки по дню).
    final laid = _buildLaidEvents(provider.filteredEvents, date, dayStart, dayEnd);
    // 2-4. Назначаем колонки и считаем ширину для пересекающихся групп.
    _assignColumns(laid);

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: _hourHeight * 24,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final eventsAreaWidth =
                constraints.maxWidth - _timeGutter - _leftPad - _rightPad;

            return Stack(
              children: [
                // Сетка часов
                Column(
                  children: List.generate(24, (hour) {
                    final currentHour = isToday && hour == now.hour;
                    return SizedBox(
                      height: _hourHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: _timeGutter,
                            child: Transform.translate(
                              offset: const Offset(0, -6),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: currentHour
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : null,
                                border: Border(
                                  top: BorderSide(
                                    color: lineColor,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                // События
                ...laid.map((laidEvent) {
                  final event = laidEvent.event;
                  final color = _eventColor(event);

                  final colWidth = eventsAreaWidth / laidEvent.columnCount;
                  final left = _timeGutter +
                      _leftPad +
                      laidEvent.columnIndex * colWidth;
                  final width = laidEvent.columnSpan * colWidth - _colGap;

                  final top = laidEvent.startMinutes / 60 * _hourHeight;
                  final height = laidEvent.heightMinutes / 60 * _hourHeight;

                  return Positioned(
                    top: top,
                    left: left,
                    width: width,
                    height: height,
                    child: GestureDetector(
                      onTap: () => _openEditDialog(context, provider, event),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border(left: BorderSide(color: color, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: (event.category == EventCategory.task && event.isCompleted)
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: (event.category == EventCategory.task && event.isCompleted)
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                            if (laidEvent.heightMinutes >= 45)
                              Text(
                                '${_hhmm(laidEvent.start)} – ${_hhmm(laidEvent.end)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Линия текущего времени
                if (isToday)
                  Positioned(
                    top: (now.hour * 60 + now.minute) / 60 * _hourHeight,
                    left: _timeGutter - 4,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1.5, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Событие, подготовленное к раскладке: эффективное время (с учётом повтора),
/// обрезанное по границам дня, + назначенная колонка/ширина.
class _LaidEvent {
  final CalendarEvent event;
  final DateTime start; // эффективное начало (обрезано по дню)
  final DateTime end; // эффективный конец (обрезан по дню)
  final int startMinutes; // минут от начала дня
  final int endMinutes; // минут от начала дня (фактический конец)
  int columnIndex = 0;
  int columnSpan = 1;
  int columnCount = 1;

  _LaidEvent({
    required this.event,
    required this.start,
    required this.end,
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Высота карточки в минутах (с учётом минимальной для читаемости).
  int get heightMinutes {
    final actual = endMinutes - startMinutes;
    return actual < _minDurationMin ? _minDurationMin : actual;
  }

  /// Пересечение по фактическому времени (касание краями не считается).
  bool overlaps(_LaidEvent other) =>
      startMinutes < other.endMinutes && endMinutes > other.startMinutes;
}

List<_LaidEvent> _buildLaidEvents(
  List<CalendarEvent> all,
  DateTime date,
  DateTime dayStart,
  DateTime dayEnd,
) {
  final result = <_LaidEvent>[];

  for (final event in all) {
    if (!event.isVisibleOnDate(date)) continue;

    DateTime eventStart = event.start;
    DateTime eventEnd = event.end;

    // Повторяющиеся события переносим на текущий день, сохраняя длительность.
    if (event.repeatType != RepeatType.none) {
      final duration = event.end.difference(event.start);
      eventStart = DateTime(
        dayStart.year,
        dayStart.month,
        dayStart.day,
        event.start.hour,
        event.start.minute,
      );
      eventEnd = eventStart.add(duration);
    }

    final start = eventStart.isBefore(dayStart) ? dayStart : eventStart;
    final end = eventEnd.isAfter(dayEnd) ? dayEnd : eventEnd;

    final startMinutes = start.difference(dayStart).inMinutes;
    final endMinutes = end.difference(dayStart).inMinutes;

    result.add(_LaidEvent(
      event: event,
      start: start,
      end: end,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    ));
  }

  // Сортировка: по началу, при равном начале — длинные выше (раньше).
  result.sort((a, b) {
    final byStart = a.startMinutes.compareTo(b.startMinutes);
    if (byStart != 0) return byStart;
    return b.endMinutes.compareTo(a.endMinutes);
  });

  return result;
}

/// Алгоритм как в Apple/Google Calendar:
/// 1) кластер транзитивно пересекающихся событий;
/// 2) жадно раскладываем по колонкам (первая колонка без пересечения);
/// 3) число колонок = размер кластера по ширине;
/// 4) расширяем карточку вправо на свободные колонки → ширина.
void _assignColumns(List<_LaidEvent> events) {
  var cluster = <_LaidEvent>[];
  var columns = <List<_LaidEvent>>[];
  int? clusterEnd;

  void flush() {
    final colCount = columns.length;
    for (var i = 0; i < colCount; i++) {
      for (final ev in columns[i]) {
        // Расширяем вправо, пока следующие колонки свободны от пересечений.
        var span = 1;
        for (var j = i + 1; j < colCount; j++) {
          final collides = columns[j].any((other) => ev.overlaps(other));
          if (collides) break;
          span++;
        }
        ev.columnIndex = i;
        ev.columnSpan = span;
        ev.columnCount = colCount;
      }
    }
    cluster = <_LaidEvent>[];
    columns = <List<_LaidEvent>>[];
    clusterEnd = null;
  }

  for (final ev in events) {
    // Новый кластер, если событие начинается не раньше конца текущего.
    if (clusterEnd != null && ev.startMinutes >= clusterEnd!) {
      flush();
    }

    var placed = false;
    for (final col in columns) {
      if (!col.last.overlaps(ev)) {
        col.add(ev);
        placed = true;
        break;
      }
    }
    if (!placed) {
      columns.add(<_LaidEvent>[ev]);
    }

    cluster.add(ev);
    if (clusterEnd == null || ev.endMinutes > clusterEnd!) {
      clusterEnd = ev.endMinutes;
    }
  }

  if (columns.isNotEmpty) flush();
}

Future<void> _openEditDialog(
  BuildContext context,
  CalendarProvider provider,
  CalendarEvent event,
) async {
  Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)));
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Color _eventColor(CalendarEvent event) {
  if (event.color != 0) {
    return Color(event.color);
  }

  final category = event.category;
  return category.color;
}
