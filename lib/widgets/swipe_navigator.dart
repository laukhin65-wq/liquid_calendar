import 'package:flutter/material.dart';

/// Период, по которому листаем страницы.
enum PeriodUnit { day, week, month, year }

/// iOS-овское перелистывание периодов: страница тянется за пальцем (PageView).
///
/// [date] — текущая выбранная дата (из провайдера).
/// [unit] — что листаем (день / неделя / месяц / год).
/// [onDateChanged] — вызывается, когда пользователь перелистнул на новую
///   страницу (обычно `provider.setDate`).
/// [pageBuilder] — строит содержимое страницы для конкретной даты периода.
///
/// Двусторонняя синхронизация: если дата меняется снаружи (кнопка «Сегодня»,
/// тап по дню, смена вида) — контроллер сам доезжает до нужной страницы.
class SwipePager extends StatefulWidget {
  final DateTime date;
  final PeriodUnit unit;
  final ValueChanged<DateTime> onDateChanged;
  final Widget Function(BuildContext context, DateTime pageDate) pageBuilder;

  const SwipePager({
    super.key,
    required this.date,
    required this.unit,
    required this.onDateChanged,
    required this.pageBuilder,
  });

  @override
  State<SwipePager> createState() => _SwipePagerState();
}

class _SwipePagerState extends State<SwipePager> {
  // Опорная точка отсчёта страниц (далеко в прошлом, чтобы индексы были > 0).
  static final DateTime _ref = DateTime(1900, 1, 1, 12);

  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _indexFor(widget.date);
    _controller = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant SwipePager oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если вид сменился — индексация другая, просто пересчитываем позицию.
    final target = _indexFor(widget.date);
    if (target == _currentPage) return;

    _currentPage = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final page = _controller.page?.round() ?? target;
      if (page == target) return;
      if ((target - page).abs() > 1 || widget.unit != oldWidget.unit) {
        _controller.jumpToPage(target);
      } else {
        _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _norm(DateTime d) {
    switch (widget.unit) {
      case PeriodUnit.day:
        return DateTime(d.year, d.month, d.day, 12);
      case PeriodUnit.week:
        return DateTime(d.year, d.month, d.day, 12)
            .subtract(Duration(days: d.weekday - 1));
      case PeriodUnit.month:
        return DateTime(d.year, d.month, 1, 12);
      case PeriodUnit.year:
        return DateTime(d.year, 1, 1, 12);
    }
  }

  int _indexFor(DateTime d) {
    final a = _norm(_ref);
    final b = _norm(d);
    switch (widget.unit) {
      case PeriodUnit.day:
        return b.difference(a).inDays;
      case PeriodUnit.week:
        return (b.difference(a).inDays / 7).round();
      case PeriodUnit.month:
        return (b.year - a.year) * 12 + (b.month - a.month);
      case PeriodUnit.year:
        return b.year - a.year;
    }
  }

  DateTime _dateFor(int index) {
    final a = _norm(_ref);
    switch (widget.unit) {
      case PeriodUnit.day:
        return a.add(Duration(days: index));
      case PeriodUnit.week:
        return a.add(Duration(days: index * 7));
      case PeriodUnit.month:
        return DateTime(a.year, a.month + index, 1, 12);
      case PeriodUnit.year:
        return DateTime(a.year + index, 1, 1, 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      onPageChanged: (index) {
        _currentPage = index;
        widget.onDateChanged(_dateFor(index));
      },
      itemBuilder: (context, index) {
        return widget.pageBuilder(context, _dateFor(index));
      },
    );
  }
}
