import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calendar_provider.dart';
import 'pill_button.dart';
import 'glass.dart';

/// Нижняя панель: «Сегодня» + быстрые кнопки (месяц / список событий).
///
/// Стекло реализовано через [PillButton] (BackdropFilter): в glass-темах
/// пилюли матовые/жидкие, в обычных — плоские. Без сторонних шейдеров.
class CalendarBottomBar extends StatelessWidget {
  const CalendarBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: LiquidGlassGroup(
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PillButton(
            inLayer: true,
            onTap: () {
              provider.setDate(DateTime.now());
              provider.setView(CalendarViewType.day);
            },
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Text(
              'Сегодня',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          PillButton(
            inLayer: true,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_view_month_outlined),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => provider.setView(CalendarViewType.month),
                ),
                IconButton(
                  icon: const Icon(Icons.inbox_outlined),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
