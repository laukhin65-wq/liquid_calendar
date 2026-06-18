import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/calendar_provider.dart';
import '../screens/search_screen.dart';
import 'pill_button.dart';
import 'glass.dart';
import '../screens/add_event_screen.dart'; // Если они в одной папке, или укажите правильный путь к экрану

/// Шапка, зависящая от текущего вида (месяц / год / день).
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<CalendarProvider>().currentView;

    if (view == CalendarViewType.year) return const _YearHeader();
    if (view == CalendarViewType.day) return const _DayHeader();
    return const _MonthHeader();
  }
}

// ─────────────────────────────────────────── Месяц
class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final date = provider.selectedDate;
    final month = _cap(DateFormat('LLLL', 'ru_RU').format(date));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiquidGlassGroup(
            child: Row(
            children: [
              PillButton(
                inLayer: true,
                onTap: () => provider.setView(CalendarViewType.year),
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 20),
                    const SizedBox(width: 2),
                    Text(
                      '${date.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ActionsPill(
                leading: Icons.view_agenda_outlined,
                  currentDate: provider.selectedDate
                   ),
                ],
          )),

          const SizedBox(height: 10),
          Text(
            month,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Год
class _YearHeader extends StatelessWidget {
  const _YearHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final year = provider.selectedDate.year;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiquidGlassGroup(
            child: Row(
            children: [
            const Spacer(),
              _ActionsPill(currentDate: provider.selectedDate),
            ],
          )),
          const SizedBox(height: 10),
          Text(
            '$year',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── День
class _DayHeader extends StatefulWidget {
  const _DayHeader();

  @override
  State<_DayHeader> createState() => _DayHeaderState();
}

class _DayHeaderState extends State<_DayHeader> {
  // Понедельник опорной недели (01.01.1900 — понедельник).
  static final DateTime _refMonday = DateTime(1900, 1, 1, 12);

  late final PageController _controller;
  late int _currentWeek;
  DateTime? _lastSelected;

  @override
  void initState() {
    super.initState();
    final selected = context.read<CalendarProvider>().selectedDate;
    _lastSelected = selected;
    _currentWeek = _weekIndex(selected);
    _controller = PageController(initialPage: _currentWeek);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day, 12).subtract(Duration(days: d.weekday - 1));

  int _weekIndex(DateTime d) =>
      (_mondayOf(d).difference(_refMonday).inDays / 7).round();

  DateTime _mondayForWeek(int index) =>
      _refMonday.add(Duration(days: index * 7));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final selected = provider.selectedDate;
    final monthName = _cap(DateFormat('LLLL', 'ru_RU').format(selected));

    // Полоса недели синхронизируется со strip ТОЛЬКО когда дата меняется
    // снаружи (тап по дню в этой же неделе ничего не двигает; «Сегодня» или
    // переход с другого экрана — доезжаем до нужной недели). Свайп полосы сам
    // по себе день не меняет, поэтому ручное листание не сбрасывается.
    if (_lastSelected == null || !_sameDay(selected, _lastSelected!)) {
      _lastSelected = selected;
      final target = _weekIndex(selected);
      if (target != _currentWeek) {
        _currentWeek = target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients) return;
          if (_controller.page?.round() == target) return;
          _controller.animateToPage(
            target,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          LiquidGlassGroup(
            child: Row(
            children: [
              PillButton(
                inLayer: true,
                onTap: () => provider.setView(CalendarViewType.month),
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 20),
                    const SizedBox(width: 2),
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ActionsPill(currentDate: provider.selectedDate),
            ],
          )),
          const SizedBox(height: 12),
          // Листаемая полоса недель: свайп = другая неделя дат, тап = выбрать день.
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) => _currentWeek = index,
              itemBuilder: (context, index) {
                final monday = _mondayForWeek(index);
                final days =
                    List.generate(7, (i) => monday.add(Duration(days: i)));
                return _WeekStrip(days: days, selected: selected);
              },
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// Одна неделя дат в полосе дня.
class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;

  const _WeekStrip({required this.days, required this.selected});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Row(
      children: days.map((day) {
        final isToday = _sameDay(day, now);
        final isSelected = _sameDay(day, selected);
        final isWeekend = day.weekday >= 6;

        // Цвет числа дня (адаптивен к теме):
        //   сегодня → белый (на красном кружке)
        //   выбран  → surface (на тёмном/светлом кружке)
        //   обычный → onSurface (выходные приглушены)
        final Color numberColor = isToday
            ? Colors.white
            : isSelected
            ? scheme.surface
            : scheme.onSurface.withValues(alpha: isWeekend ? 0.5 : 1.0);

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => provider.setDate(day),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _weekdayLetter(day.weekday),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(
                      alpha: isWeekend ? 0.45 : 0.65,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.red
                        : (isSelected
                              ? scheme.onSurface.withValues(alpha: 0.85)
                              : null),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: numberColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────── Общие части

class _ActionsPill extends StatelessWidget {
  final IconData? leading;
  final DateTime currentDate; // Добавляем поле для текущей даты экрана

  const _ActionsPill({
    this.leading,
    required this.currentDate, // Делаем обязательным
  });

  @override
  Widget build(BuildContext context) {
    return PillButton(
      inLayer: true,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null)
            IconButton(
              icon: Icon(leading),
              visualDensity: VisualDensity.compact,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.push(
              context,
              MaterialPageRoute(
              // ИСПРАВЛЕНИЕ: Передаём точную дату в диалог!
              builder: (context) => const AddEventScreen(),
            ),
          );
         },
         ),
        ],
      ),
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayLetter(int weekday) {
  const letters = ['п', 'в', 'с', 'ч', 'п', 'с', 'в'];
  return letters[(weekday - 1) % 7];
}
