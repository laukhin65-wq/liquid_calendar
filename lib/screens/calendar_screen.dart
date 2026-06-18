import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calendar_provider.dart';
import '../data/models/event_category.dart';
import 'day/day_screen.dart';
import 'week/week_screen.dart';
import 'month/month_screen.dart';
import 'year/year_screen.dart';
import '../widgets/calendar_header.dart';
import '../widgets/calendar_bottom_bar.dart';
import 'event_detail_screen.dart';
import '../widgets/zoom_transition_switcher.dart';
import '../widgets/glass.dart';
import 'theme_settings_screen.dart';
import 'schedule_screen.dart';
import 'life_screen.dart';

/// Глубина вида для zoom-перехода: чем больше — тем «глубже» (наезд).
/// Подложка-градиент под стекло — только в glass-режиме.
Widget _maybeGlass(bool glass, Widget child) =>
    glass ? GlassBackdrop(child: child) : child;

int _viewDepth(CalendarViewType v) {
  switch (v) {
    case CalendarViewType.year:
      return 0;
    case CalendarViewType.month:
      return 1;
    case CalendarViewType.week:
      return 2;
    case CalendarViewType.day:
      return 3;
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final glass = isGlassTheme(context);

    Widget currentScreen;
    switch (provider.currentView) {
      case CalendarViewType.day:
        currentScreen = const DayScreen();
        break;
      case CalendarViewType.week:
        currentScreen = const WeekScreen();
        break;
      case CalendarViewType.month:
        currentScreen = const MonthScreen();
        break;
      case CalendarViewType.year:
        currentScreen = const YearScreen();
        break;
    }

    // Системный «назад» Android (edge-swipe): с вкладок Год и День всегда
    // возвращаемся на Месяц. На Месяц/Неделя — обычное поведение (выход).
    final view = provider.currentView;
    final interceptBack =
        view == CalendarViewType.year || view == CalendarViewType.day;

    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        provider.setView(CalendarViewType.month);
      },
      child: Scaffold(
        drawer: _EventsDrawer(key: ValueKey(provider.selectedDate)),
        body: _maybeGlass(
          glass,
          SafeArea(
            // Прокрутка любого вложенного списка плавно двигает блик стекла.
            child: GlassShimmerDriver(
              child: Column(
          children: [
            const CalendarHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<Offset?>(
                  valueListenable: zoomAnchor,
                  builder: (_, anchor, _) => ZoomTransitionSwitcher(
                    depth: _viewDepth(provider.currentView),
                    anchorGlobal: anchor,
                    child: KeyedSubtree(
                      key: ValueKey(provider.currentView),
                      child: currentScreen,
                    ),
                  ),
                ),
              ),
            ),
            const CalendarBottomBar(),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsDrawer extends StatelessWidget {
  const _EventsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context);
    final events = provider.eventsForDate(provider.selectedDate);
    final glass = isGlassTheme(context);

    final content = ListView(
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('LIFE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Календарь жизни', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Расписание'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Моя жизнь'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LifeScreen()),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'События дня',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет событий'),
            ),
          ...events.map(
            (event) {
              final isHoliday = event.category == EventCategory.holiday;
              return Dismissible(
              key: ValueKey(event.id),
              direction: isHoliday ? DismissDirection.none : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await provider.deleteEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${event.title}" удалено')),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: event.category.color, width: 3),
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.circle, size: 10, color: event.category.color),
                  title: Text(
                    event.title,
                    style: TextStyle(
                      decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                      color: event.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  subtitle: isHoliday
                      ? Text(event.category.label)
                      : Text(
                    '${event.category.label}   '
                    '${event.start.hour.toString().padLeft(2, '0')}:'
                    '${event.start.minute.toString().padLeft(2, '0')}'
                    ' – '
                    '${event.end.hour.toString().padLeft(2, '0')}:'
                    '${event.end.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)));
                  },
                ),
              ),
            );
            },
          ),
          const Divider(),
          // ── Фильтр категорий ──
          _CategoryFilterSection(provider: provider),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Тема'),
            onTap: () {
              Navigator.pop(context); // закрыть боковое меню
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
        ],
    );

    // Обычные темы — стандартное меню.
    if (!glass) return Drawer(child: content);

    // Стеклянное боковое меню в стиле Liquid Glass: сильное размытие
    // сцены позади, лёгкая (не «молочная») заливка с бликом,
    // скруглённый правый край с линзовой окантовкой — как панели iOS 26.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const drawerRadius = BorderRadius.only(
      topRight: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: drawerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: CustomPaint(
            foregroundPainter: LensBorderPainter(
              borderRadius: drawerRadius,
              isDark: isDark,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
                    Colors.white.withValues(alpha: isDark ? 0.03 : 0.10),
                  ],
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Секция фильтра категорий в drawer: выпадающий список с чекбоксами.
class _CategoryFilterSection extends StatelessWidget {
  final CalendarProvider provider;
  const _CategoryFilterSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final expanded = provider.filterExpanded;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.filter_list),
          title: const Text('Категории'),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => provider.toggleFilterExpanded(),
        ),
        if (expanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => provider.setAllCategoriesVisible(),
                child: Text('Все',
                    style: TextStyle(fontSize: 12, color: scheme.primary)),
              ),
            ),
          ),
          for (final cat in EventCategory.values)
            CheckboxListTile(
              value: provider.isCategoryVisible(cat),
              onChanged: (_) => provider.toggleCategory(cat),
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(cat.label, style: const TextStyle(fontSize: 14)),
                ],
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
        ],
      ],
    );
  }
}
