import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/life_statistics.dart';
import '../../data/models/category_analytics.dart';
import '../../data/models/people_analytics.dart';
import '../../data/models/location_analytics.dart';
import '../../data/models/today_stats.dart';
import '../../data/models/week_stats.dart';
import '../../data/models/event_category.dart';
import '../../services/life_statistics_service.dart';
import '../../services/category_analytics_service.dart';
import '../../services/people_analytics_service.dart';
import '../../services/location_analytics_service.dart';
import '../../services/today_stats_service.dart';
import '../../services/week_stats_service.dart';
import '../../widgets/glass.dart';
import 'event_detail_screen.dart';

class LifeScreen extends StatefulWidget {
  const LifeScreen({super.key});

  @override
  State<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends State<LifeScreen>
    with SingleTickerProviderStateMixin {
  final _service = LifeStatisticsService();
  final _categoryService = CategoryAnalyticsService();
  final _peopleService = PeopleAnalyticsService();
  final _locationService = LocationAnalyticsService();
  final _todayService = TodayStatsService();
  final _weekService = WeekStatsService();

  late LifeStatistics _stats;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  CategoryAnalyticsModel? _categoryStats;
  PeopleAnalyticsModel? _peopleStats;
  LocationAnalyticsModel? _locationStats;
  TodayStatsModel? _todayStats;
  WeekStatsModel? _weekStats;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllStats() {
    setState(() {
      _stats = _service.calculate();
      _categoryStats = _categoryService.calculate(_selectedPeriod);
      _peopleStats = _peopleService.calculate();
      _locationStats = _locationService.calculate();
      _todayStats = _todayService.calculate();
      _weekStats = _weekService.calculate();
    });
  }

  void _loadCategoryStats() {
    setState(() {
      _categoryStats = _categoryService.calculate(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = isGlassTheme(context);

    Widget screenContent = Scaffold(
      backgroundColor: glass ? Colors.transparent : null,
      appBar: AppBar(
        backgroundColor: glass ? Colors.transparent : null,
        title: const Text('Моя жизнь'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Сегодня'),
            Tab(text: 'Неделя'),
            Tab(text: 'Ритм жизни'),
            Tab(text: 'Люди'),
            Tab(text: 'Места'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildWeekTab(),
          _buildOverviewTab(),
          _buildPeopleTab(),
          _buildLocationsTab(),
        ],
      ),
    );

    if (!glass) return screenContent;
    return GlassBackdrop(child: screenContent);
  }

  Widget _buildTodayTab() {
    final stats = _todayStats;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTodayStatsCards(stats),
        const SizedBox(height: 16),
        _buildTodayProductivityBlock(stats),
        const SizedBox(height: 16),
        _buildTodayTimeAnalyticsBlock(stats),
        const SizedBox(height: 16),
        if (stats.contacts.isNotEmpty) ...[
          _buildTodayContactsBlock(stats),
          const SizedBox(height: 16),
        ],
        if (stats.locations.isNotEmpty) ...[
          _buildTodayLocationsBlock(stats),
          const SizedBox(height: 16),
        ],
        _buildTodayTimelineBlock(stats),
        const SizedBox(height: 16),
        _buildTodaySummaryBlock(stats),
      ],
    );
  }

  Widget _buildWeekTab() {
    final stats = _weekStats;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeekStatsCards(stats),
        const SizedBox(height: 16),
        _buildWeekProductivityBlock(stats),
        const SizedBox(height: 16),
        _buildWeekTimeAnalyticsBlock(stats),
        const SizedBox(height: 16),
        if (stats.contacts.isNotEmpty) ...[
          _buildWeekContactsBlock(stats),
          const SizedBox(height: 16),
        ],
        if (stats.locations.isNotEmpty) ...[
          _buildWeekLocationsBlock(stats),
          const SizedBox(height: 16),
        ],
        _buildWeekTimelineBlock(stats),
        const SizedBox(height: 16),
        _buildWeekSummaryBlock(stats),
      ],
    );
  }

  Widget _buildWeekStatsCards(WeekStatsModel stats) {
    return _Section(
      title: 'Показатели недели',
      child: Column(
        children: [
          _StatRow(
            icon: Icons.calendar_month,
            label: 'Событий',
            value: '${stats.totalEvents}',
            color: Colors.blue,
          ),
          _StatRow(
            icon: Icons.check_circle_outline,
            label: 'Задач',
            value: '${stats.totalTasks}',
            color: Colors.green,
          ),
          _StatRow(
            icon: Icons.task_alt,
            label: 'Выполненных задач',
            value: '${stats.completedTasks}',
            color: Colors.teal,
          ),
          _StatRow(
            icon: Icons.person_outline,
            label: 'Контактов',
            value: '${stats.uniqueContacts}',
            color: Colors.orange,
          ),
          _StatRow(
            icon: Icons.location_on_outlined,
            label: 'Мест',
            value: '${stats.uniqueLocations}',
            color: Colors.red,
          ),
          _StatRow(
            icon: Icons.attach_file,
            label: 'Вложения',
            value: '${_getWeekAttachments(stats)}',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  int _getWeekAttachments(WeekStatsModel stats) {
    int count = 0;
    for (final event in stats.timeline) {
      if (event.attachments != null) {
        count += event.attachments!.length;
      }
    }
    return count;
  }

  Widget _buildWeekProductivityBlock(WeekStatsModel stats) {
    return _Section(
      title: 'Продуктивность недели',
      child: Row(
        children: [
          Expanded(
            child: _ProductivityIndicator(
              percentage: stats.productivityPercentage,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniStat(
                  label: 'Всего задач',
                  value: '${stats.totalTasks}',
                ),
                const SizedBox(height: 8),
                _MiniStat(
                  label: 'Выполнено',
                  value: '${stats.completedTasks}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTimeAnalyticsBlock(WeekStatsModel stats) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekEvents = _service.getEventsInRange(weekStart, weekEnd);

    final categoryHours = <String, double>{};
    double totalHours = 0;
    for (final event in weekEvents) {
      final cat = event.category;
      final hours = event.end.difference(event.start).inMinutes / 60.0;
      categoryHours[cat.label] = (categoryHours[cat.label] ?? 0) + hours;
      totalHours += hours;
    }

    if (categoryHours.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalStr = totalHours == totalHours.roundToDouble()
        ? '${totalHours.toInt()}ч'
        : '${totalHours.toStringAsFixed(1)}ч';

    return _Section(
      title: 'Аналитика времени',
      child: Column(
        children: [
          for (final entry in sortedCategories)
            _StatRow(
              icon: Icons.category_outlined,
              label: entry.key,
              value: '${entry.value == entry.value.roundToDouble() ? entry.value.toInt() : entry.value.toStringAsFixed(1)}ч',
              color: Colors.blue,
            ),
          const Divider(height: 20),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'Итого затрачено часов',
            value: totalStr,
            color: Colors.indigo,
          ),
          if (stats.mostActiveDay != null)
            _StatRow(
              icon: Icons.bolt,
              label: 'Самый активный день',
              value: stats.mostActiveDay!,
              color: Colors.amber,
            ),
        ],
      ),
    );
  }

  Widget _buildWeekContactsBlock(WeekStatsModel stats) {
    return _Section(
      title: 'Контакты недели',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats.contacts.map((contact) {
          final name = contact.contains(' | ') ? contact.split(' | ').first : contact;
          final phone = contact.contains(' | ') ? contact.split(' | ').last : '';
          return GestureDetector(
            onTap: phone.isNotEmpty ? () => _dialPhone(phone) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.phone, size: 14, color: Theme.of(context).colorScheme.primary),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekLocationsBlock(WeekStatsModel stats) {
    return _Section(
      title: 'Места недели',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats.locations.map((location) {
          return GestureDetector(
            onTap: () => _openMap(location),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 12, color: Colors.orange.withValues(alpha: 0.7)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekTimelineBlock(WeekStatsModel stats) {
    if (stats.timeline.isEmpty) {
      return _Section(
      title: 'Таймлайн недели',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Нет событий на этой неделе',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return _Section(
      title: 'Таймлайн недели',
      child: Column(
        children: stats.timeline.take(10).map((event) {
          final cat = event.category;
          final dateStr = DateFormat('dd.MM').format(event.start);
          final timeStr = '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';

          return GestureDetector(
            onTap: () => _openEventDetail(event.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                            color: event.isCompleted ? Colors.grey : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekSummaryBlock(WeekStatsModel stats) {
    return _Section(
      title: 'Итоги недели',
      child: Text(
        stats.summaryText,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAllTimeBlock(context),
        const SizedBox(height: 16),
        _buildProductivityBlock(context),
        const SizedBox(height: 16),
        _buildMonthBlock(context),
        const SizedBox(height: 16),
        _buildMonthSummaryBlock(context),
        const SizedBox(height: 16),
        _buildLifeBalanceBlock(context),
        const SizedBox(height: 16),
        _buildTimeAnalyticsBlock(context),
        const SizedBox(height: 16),
        _buildPeriodSummaryBlock(context),
      ],
    );
  }

  Widget _buildTodayStatsCards(TodayStatsModel stats) {
    return _Section(
      title: 'Показатели дня',
      child: Column(
        children: [
          _StatRow(
            icon: Icons.calendar_month,
            label: 'Событий',
            value: '${stats.totalEvents}',
            color: Colors.blue,
          ),
          _StatRow(
            icon: Icons.check_circle_outline,
            label: 'Задач',
            value: '${stats.totalTasks}',
            color: Colors.green,
          ),
          _StatRow(
            icon: Icons.task_alt,
            label: 'Выполненных задач',
            value: '${stats.completedTasks}',
            color: Colors.teal,
          ),
          _StatRow(
            icon: Icons.person_outline,
            label: 'Контактов',
            value: '${stats.uniqueContacts}',
            color: Colors.orange,
          ),
          _StatRow(
            icon: Icons.location_on_outlined,
            label: 'Мест',
            value: '${stats.uniqueLocations}',
            color: Colors.red,
          ),
          _StatRow(
            icon: Icons.attach_file,
            label: 'Вложения',
            value: '${_getTodayAttachments(stats)}',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  int _getTodayAttachments(TodayStatsModel stats) {
    int count = 0;
    for (final event in stats.timeline) {
      if (event.attachments != null) {
        count += event.attachments!.length;
      }
    }
    return count;
  }

  Widget _buildTodayProductivityBlock(TodayStatsModel stats) {
    return _Section(
      title: 'Продуктивность дня',
      child: Row(
        children: [
          Expanded(
            child: _ProductivityIndicator(
              percentage: stats.productivityPercentage,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniStat(
                  label: 'Всего задач',
                  value: '${stats.totalTasks}',
                ),
                const SizedBox(height: 8),
                _MiniStat(
                  label: 'Выполнено',
                  value: '${stats.completedTasks}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTimeAnalyticsBlock(TodayStatsModel stats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEvents = _service.getEventsForDate(today);

    final categoryHours = <String, double>{};
    double totalHours = 0;
    for (final event in todayEvents) {
      final cat = event.category;
      final hours = event.end.difference(event.start).inMinutes / 60.0;
      categoryHours[cat.label] = (categoryHours[cat.label] ?? 0) + hours;
      totalHours += hours;
    }

    if (categoryHours.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalStr = totalHours == totalHours.roundToDouble()
        ? '${totalHours.toInt()}ч'
        : '${totalHours.toStringAsFixed(1)}ч';

    return _Section(
      title: 'Аналитика времени',
      child: Column(
        children: [
          for (final entry in sortedCategories)
            _StatRow(
              icon: Icons.category_outlined,
              label: entry.key,
              value: '${entry.value == entry.value.roundToDouble() ? entry.value.toInt() : entry.value.toStringAsFixed(1)}ч',
              color: Colors.blue,
            ),
          const Divider(height: 20),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'Итого затрачено часов',
            value: totalStr,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayContactsBlock(TodayStatsModel stats) {
    return _Section(
      title: 'Контакты дня',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats.contacts.map((contact) {
          final name = stats.contactName(contact);
          final phone = stats.contactPhone(contact);
          return GestureDetector(
            onTap: phone.isNotEmpty ? () => _dialPhone(phone) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.phone, size: 14, color: Theme.of(context).colorScheme.primary),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodayLocationsBlock(TodayStatsModel stats) {
    return _Section(
      title: 'Места дня',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats.locations.map((location) {
          return GestureDetector(
            onTap: () => _openMap(location),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 12, color: Colors.orange.withValues(alpha: 0.7)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodayTimelineBlock(TodayStatsModel stats) {
    if (stats.timeline.isEmpty) {
      return _Section(
      title: 'Таймлайн дня',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Нет событий на сегодня',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return _Section(
      title: 'Таймлайн дня',
      child: Column(
        children: stats.timeline.map((event) {
          final cat = event.category;
          final timeStr = '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';
          final endTimeStr = '${event.end.hour.toString().padLeft(2, '0')}:${event.end.minute.toString().padLeft(2, '0')}';

          return GestureDetector(
            onTap: () => _openEventDetail(event.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                            color: event.isCompleted ? Colors.grey : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$endTimeStr · ${cat.label}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _dialPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent(location);
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openEventDetail(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: eventId),
      ),
    );
  }

  Widget _buildTodaySummaryBlock(TodayStatsModel stats) {
    return _Section(
      title: 'Итог дня',
      child: Text(
        stats.summaryText,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildPeopleTab() {
    final stats = _peopleStats;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeopleStatsCards(stats),
        const SizedBox(height: 16),
        _buildTopContactsBlock(stats),
        const SizedBox(height: 16),
        _buildPeopleSummaryBlock(stats),
      ],
    );
  }

  Widget _buildLocationsTab() {
    final stats = _locationStats;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLocationStatsCards(stats),
        const SizedBox(height: 16),
        _buildTopLocationsBlock(stats),
        const SizedBox(height: 16),
        _buildLocationSummaryBlock(stats),
      ],
    );
  }

  Widget _buildAllTimeBlock(BuildContext context) {
    return _Section(
      title: 'За всё время',
      child: Column(
        children: [
          _StatRow(
            icon: Icons.calendar_month,
            label: 'События',
            value: '${_stats.allTime.totalEvents}',
            color: Colors.blue,
          ),
          _StatRow(
            icon: Icons.check_circle_outline,
            label: 'Задачи',
            value: '${_stats.allTime.totalTasks}',
            color: Colors.green,
          ),
          _StatRow(
            icon: Icons.task_alt,
            label: 'Выполненные задачи',
            value: '${_stats.allTime.completedTasks}',
            color: Colors.teal,
          ),
          _StatRow(
            icon: Icons.person_outline,
            label: 'Контакты',
            value: '${_stats.allTime.uniqueContacts}',
            color: Colors.purple,
          ),
          _StatRow(
            icon: Icons.location_on_outlined,
            label: 'Места',
            value: '${_stats.allTime.uniqueLocations}',
            color: Colors.orange,
          ),
          _StatRow(
            icon: Icons.attach_file,
            label: 'Вложения',
            value: '${_stats.allTime.totalAttachments}',
            color: Colors.teal,
          ),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'Затрачено часов',
            value: _formatHours(_stats.allTime.totalHours),
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityBlock(BuildContext context) {
    return _Section(
      title: 'Продуктивность',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProductivityIndicator(
                  percentage: _stats.productivity.percentage,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniStat(
                      label: 'Создано',
                      value: '${_stats.productivity.createdTasks}',
                    ),
                    const SizedBox(height: 8),
                    _MiniStat(
                      label: 'Выполнено',
                      value: '${_stats.productivity.completedTasks}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBlock(BuildContext context) {
    return _Section(
      title: 'Этот месяц',
      child: Column(
        children: [
          _StatRow(
            icon: Icons.calendar_month,
            label: 'Событий за месяц',
            value: '${_stats.currentMonth.events}',
            color: Colors.blue,
          ),
          _StatRow(
            icon: Icons.check_circle_outline,
            label: 'Выполненных задач за месяц',
            value: '${_stats.currentMonth.completedTasks}',
            color: Colors.green,
          ),
          _StatRow(
            icon: Icons.person_outline,
            label: 'Контактов за месяц',
            value: '${_stats.currentMonth.uniqueContacts}',
            color: Colors.purple,
          ),
          _StatRow(
            icon: Icons.location_on_outlined,
            label: 'Посещённых мест за месяц',
            value: '${_stats.currentMonth.uniqueLocations}',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryBlock(BuildContext context) {
    final summary = _stats.monthSummary;
    final lines = <String>[];

    if (summary.events > 0) lines.add('Создано ${summary.events} событий');
    if (summary.completedTasks > 0) {
      lines.add('Выполнено ${summary.completedTasks} задач');
    }
    if (summary.locations > 0) {
      lines.add('Использовано ${summary.locations} мест');
    }
    if (summary.meetings > 0) {
      lines.add('Проведено ${summary.meetings} встреч');
    }

    return _Section(
      title: 'Итоги месяца',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isEmpty)
            const Text(
              'Пока нет данных',
              style: TextStyle(fontSize: 14),
            )
          else
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $line',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          if (summary.mostActiveDay != null) ...[
            const SizedBox(height: 12),
            Text(
              'Самый активный день: ${summary.mostActiveDay} (${_formatMostActiveDayDate(context)})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifeBalanceBlock(BuildContext context) {
    final stats = _categoryStats;
    if (stats == null || stats.categories.isEmpty) {
      return _Section(
        title: 'Баланс жизни',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Нет данных для отображения',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }

    return _Section(
      title: 'Баланс жизни',
      child: Column(
        children: [
          _PeriodSelector(
            selected: _selectedPeriod,
            onChanged: (period) {
              setState(() {
                _selectedPeriod = period;
                _loadCategoryStats();
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(stats),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryLegend(stats),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(CategoryAnalyticsModel stats) {
    return stats.categories.map((cat) {
      return PieChartSectionData(
        value: cat.hours,
        title: '${cat.percentage.toInt()}%',
        color: cat.category.color,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend(CategoryAnalyticsModel stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: stats.categories.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cat.category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat.category.label} — ${cat.percentage.toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimeAnalyticsBlock(BuildContext context) {
    final stats = _categoryStats;
    if (stats == null || stats.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = stats.categories.toList()
      ..sort((a, b) => b.hours.compareTo(a.hours));

    final totalStr = stats.totalHours == stats.totalHours.roundToDouble()
        ? '${stats.totalHours.toInt()}ч'
        : '${stats.totalHours.toStringAsFixed(1)}ч';

    return _Section(
      title: 'Аналитика времени',
      child: Column(
        children: [
          for (final cat in sortedCategories)
            _StatRow(
              icon: Icons.category_outlined,
              label: cat.category.label,
              value: '${cat.hours == cat.hours.roundToDouble() ? cat.hours.toInt() : cat.hours.toStringAsFixed(1)}ч',
              color: cat.category.color,
            ),
          const Divider(height: 20),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'Итого потрачено часов',
            value: totalStr,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummaryBlock(BuildContext context) {
    final stats = _categoryStats;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: 'Итоги периода',
      child: Text(
        stats.summaryText,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildPeopleStatsCards(PeopleAnalyticsModel stats) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.person_outline,
            label: 'Уникальных контактов',
            value: '${stats.uniqueContacts}',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.handshake_outlined,
            label: 'Всего встреч',
            value: '${stats.totalMeetings}',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTopContactsBlock(PeopleAnalyticsModel stats) {
    final topContacts = stats.contacts.take(10).toList();

    return _Section(
      title: 'ТОП контактов',
      child: Column(
        children: [
          if (topContacts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет данных о контактах',
                style: TextStyle(fontSize: 14),
              ),
            )
          else
            for (int i = 0; i < topContacts.length; i++)
              _ContactTile(
                rank: i + 1,
                contact: topContacts[i],
              ),
        ],
      ),
    );
  }

  Widget _buildPeopleSummaryBlock(PeopleAnalyticsModel stats) {
    return _Section(
      title: 'Выводы',
      child: Text(
        stats.summaryText,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildLocationStatsCards(LocationAnalyticsModel stats) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.location_on_outlined,
            label: 'Уникальных мест',
            value: '${stats.uniqueLocations}',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.map_outlined,
            label: 'Всего посещений',
            value: '${stats.totalVisits}',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildTopLocationsBlock(LocationAnalyticsModel stats) {
    final topLocations = stats.locations.take(10).toList();

    return _Section(
      title: 'ТОП мест',
      child: Column(
        children: [
          if (topLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет данных о местах',
                style: TextStyle(fontSize: 14),
              ),
            )
          else
            for (int i = 0; i < topLocations.length; i++)
              _LocationTile(
                rank: i + 1,
                location: topLocations[i],
              ),
        ],
      ),
    );
  }

  Widget _buildLocationSummaryBlock(LocationAnalyticsModel stats) {
    return _Section(
      title: 'Выводы',
      child: Text(
        stats.summaryText,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  String _formatMostActiveDayDate(BuildContext context) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final daysToMonday = currentWeekday - 1;
    final monday = DateTime(now.year, now.month, now.day - daysToMonday);

    final mostActiveDayName = _stats.monthSummary.mostActiveDay;
    if (mostActiveDayName == null) return '';

    int mostActiveWeekday = 1;
    switch (mostActiveDayName) {
      case 'Понедельник': mostActiveWeekday = 1; break;
      case 'Вторник': mostActiveWeekday = 2; break;
      case 'Среда': mostActiveWeekday = 3; break;
      case 'Четверг': mostActiveWeekday = 4; break;
      case 'Пятница': mostActiveWeekday = 5; break;
      case 'Суббота': mostActiveWeekday = 6; break;
      case 'Воскресенье': mostActiveWeekday = 7; break;
    }

    final targetDate = monday.add(Duration(days: mostActiveWeekday - 1));
    final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${targetDate.day} ${months[targetDate.month - 1]}';
  }

  String _formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}';
    }
    return hours.toStringAsFixed(1);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final glass = isGlassTheme(context);
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: glass
            ? (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.45))
            : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: glass
            ? Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.3),
                width: 0.5,
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ProductivityIndicator extends StatelessWidget {
  final double percentage;

  const _ProductivityIndicator({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(percentage),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Продуктивность',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsPeriod>(
      segments: AnalyticsPeriod.values.map((period) {
        return ButtonSegment<AnalyticsPeriod>(
          value: period,
          label: Text(period.label, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final glass = isGlassTheme(context);
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glass
            ? (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.45))
            : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: glass
            ? Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.3),
                width: 0.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final int rank;
  final ContactData contact;

  const _ContactTile({
    required this.rank,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.amber : onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purple.withValues(alpha: 0.2),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${contact.meetingCount} встреч • ${contact.totalHours.toStringAsFixed(1)} ч',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (contact.lastMeetingDate != null)
                  Text(
                    'Последняя встреча: ${dateFormat.format(contact.lastMeetingDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final int rank;
  final LocationData location;

  const _LocationTile({
    required this.rank,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.amber : onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            child: const Icon(
              Icons.location_on,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.visitCount} событий • ${location.totalHours.toStringAsFixed(1)} ч',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (location.lastVisitDate != null)
                  Text(
                    'Последнее посещение: ${dateFormat.format(location.lastVisitDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
