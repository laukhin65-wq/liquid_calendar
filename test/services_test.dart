import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';
import 'package:liquid_calendar/data/models/category_analytics.dart';
import 'package:liquid_calendar/services/category_analytics_service.dart';
import 'package:liquid_calendar/services/today_stats_service.dart';
import 'package:liquid_calendar/services/week_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }
    await Hive.openBox<CalendarEvent>('events');
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  CalendarEvent createEvent({
    String? id,
    String title = 'Test Event',
    DateTime? start,
    DateTime? end,
    EventCategory category = EventCategory.personal,
    RepeatType repeatType = RepeatType.none,
    bool isCompleted = false,
  }) {
    return CalendarEvent(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      start: start ?? DateTime(2025, 1, 15, 10, 0),
      end: end ?? DateTime(2025, 1, 15, 11, 0),
      color: 0,
      repeatType: repeatType,
      category: category,
      isCompleted: isCompleted,
    );
  }

  group('CategoryAnalyticsService', () {
    test('calculate returns empty model when no events', () {
      final service = CategoryAnalyticsService();
      final model = service.calculate(AnalyticsPeriod.month);
      expect(model.categories, isEmpty);
      expect(model.totalHours, 0);
    });

    test('calculate groups events by category', () {
      final box = Hive.box<CalendarEvent>('events');
      box.put('1', createEvent(
        category: EventCategory.work,
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 12, 0),
      ));
      box.put('2', createEvent(
        id: '2',
        category: EventCategory.work,
        start: DateTime(2025, 1, 16, 10, 0),
        end: DateTime(2025, 1, 16, 11, 0),
      ));
      box.put('3', createEvent(
        id: '3',
        category: EventCategory.sport,
        start: DateTime(2025, 1, 17, 10, 0),
        end: DateTime(2025, 1, 17, 11, 0),
      ));

      final service = CategoryAnalyticsService();
      final model = service.calculate(AnalyticsPeriod.allTime);

      expect(model.categories.length, 2);
      expect(model.totalHours, 4.0);
    });

    test('calculate excludes holidays', () {
      final box = Hive.box<CalendarEvent>('events');
      box.put('1', createEvent(category: EventCategory.holiday));

      final service = CategoryAnalyticsService();
      final model = service.calculate(AnalyticsPeriod.allTime);

      expect(model.categories, isEmpty);
    });
  });

  group('TodayStatsService', () {
    test('calculate returns empty model when no events', () {
      final service = TodayStatsService();
      final model = service.calculate();
      expect(model.totalEvents, 0);
      expect(model.totalTasks, 0);
      expect(model.completedTasks, 0);
    });

    test('calculate counts today events', () {
      final now = DateTime.now();
      final box = Hive.box<CalendarEvent>('events');

      box.put('1', createEvent(
        title: 'Today Event',
        start: DateTime(now.year, now.month, now.day, 10, 0),
        end: DateTime(now.year, now.month, now.day, 11, 0),
      ));

      final service = TodayStatsService();
      final model = service.calculate();

      expect(model.totalEvents, 1);
    });

    test('calculate counts tasks', () {
      final now = DateTime.now();
      final box = Hive.box<CalendarEvent>('events');

      box.put('1', createEvent(
        title: 'Task 1',
        category: EventCategory.task,
        start: DateTime(now.year, now.month, now.day, 10, 0),
        end: DateTime(now.year, now.month, now.day, 11, 0),
      ));

      box.put('2', createEvent(
        id: '2',
        title: 'Task 2',
        category: EventCategory.task,
        start: DateTime(now.year, now.month, now.day, 12, 0),
        end: DateTime(now.year, now.month, now.day, 13, 0),
        isCompleted: true,
      ));

      final service = TodayStatsService();
      final model = service.calculate();

      expect(model.totalTasks, 2);
      expect(model.completedTasks, 1);
    });
  });

  group('WeekStatsService', () {
    test('calculate returns empty model when no events', () {
      final service = WeekStatsService();
      final model = service.calculate();
      expect(model.totalEvents, 0);
    });

    test('calculate counts week events', () {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final box = Hive.box<CalendarEvent>('events');

      box.put('1', createEvent(
        title: 'Week Event',
        start: DateTime(weekStart.year, weekStart.month, weekStart.day, 10, 0),
        end: DateTime(weekStart.year, weekStart.month, weekStart.day, 11, 0),
      ));

      final service = WeekStatsService();
      final model = service.calculate();

      expect(model.totalEvents, 1);
    });
  });
}
