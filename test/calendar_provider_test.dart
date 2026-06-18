import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';
import 'package:liquid_calendar/providers/calendar_provider.dart';

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

  group('CalendarProvider — events', () {
    test('events returns empty list when no events', () {
      final provider = CalendarProvider();
      expect(provider.events, isEmpty);
    });

    test('getEventById returns null for non-existent id', () {
      final provider = CalendarProvider();
      expect(provider.getEventById('nonexistent'), isNull);
    });
  });

  group('CalendarProvider — navigation', () {
    test('setDate updates selectedDate', () {
      final provider = CalendarProvider();
      final newDate = DateTime(2025, 6, 15);
      provider.setDate(newDate);
      expect(provider.selectedDate, newDate);
    });

    test('setView updates currentView', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.day);
      expect(provider.currentView, CalendarViewType.day);
    });

    test('goToToday resets to current date', () {
      final provider = CalendarProvider();
      provider.setDate(DateTime(2020, 1, 1));
      provider.goToToday();
      expect(provider.selectedDate.year, DateTime.now().year);
      expect(provider.selectedDate.month, DateTime.now().month);
      expect(provider.selectedDate.day, DateTime.now().day);
    });
  });

  group('CalendarProvider — category filter', () {
    test('all categories visible by default', () {
      final provider = CalendarProvider();
      expect(provider.isCategoryVisible(EventCategory.work), isTrue);
      expect(provider.isCategoryVisible(EventCategory.sport), isTrue);
      expect(provider.isCategoryVisible(EventCategory.holiday), isTrue);
    });

    test('toggleCategory hides category', () {
      final provider = CalendarProvider();
      provider.toggleCategory(EventCategory.work);
      expect(provider.isCategoryVisible(EventCategory.work), isFalse);
      expect(provider.isCategoryVisible(EventCategory.sport), isTrue);
    });

    test('toggleCategory shows category again', () {
      final provider = CalendarProvider();
      provider.toggleCategory(EventCategory.work);
      provider.toggleCategory(EventCategory.work);
      expect(provider.isCategoryVisible(EventCategory.work), isTrue);
    });

    test('setAllCategoriesVisible resets filter', () {
      final provider = CalendarProvider();
      provider.toggleCategory(EventCategory.work);
      provider.toggleCategory(EventCategory.sport);
      provider.setAllCategoriesVisible();
      expect(provider.isCategoryVisible(EventCategory.work), isTrue);
      expect(provider.isCategoryVisible(EventCategory.sport), isTrue);
    });

    test('toggleFilterExpanded toggles state', () {
      final provider = CalendarProvider();
      expect(provider.filterExpanded, isFalse);
      provider.toggleFilterExpanded();
      expect(provider.filterExpanded, isTrue);
      provider.toggleFilterExpanded();
      expect(provider.filterExpanded, isFalse);
    });
  });

  group('CalendarProvider — filteredEvents', () {
    test('filteredEvents excludes hidden categories', () {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      eventsBox.put('1', CalendarEvent(
        id: '1',
        title: 'Work Event',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      eventsBox.put('2', CalendarEvent(
        id: '2',
        title: 'Sport Event',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.sport,
      ));

      provider.toggleCategory(EventCategory.work);

      expect(provider.filteredEvents.length, 1);
      expect(provider.filteredEvents.first.title, 'Sport Event');
    });
  });
}
