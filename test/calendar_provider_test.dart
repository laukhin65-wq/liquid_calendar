import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';
import 'package:liquid_calendar/data/models/reminder_offset.dart';
import 'package:liquid_calendar/providers/calendar_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final widgetChannel = MethodChannel('com.example.liquid_calendar/widget');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(widgetChannel, (call) async => null);

  final alarmChannel = MethodChannel('dev.fluttercommunity.plus/android_alarm_manager');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(alarmChannel, (call) async => true);

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

  group('CalendarProvider — addEvent', () {
    test('addEvent creates event in Hive', () async {
      final provider = CalendarProvider();
      await provider.addEvent(
        title: 'Test Event',
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
        repeatType: RepeatType.none,
        category: EventCategory.work,
      );

      expect(provider.events.length, 1);
      expect(provider.events.first.title, 'Test Event');
    });

    test('addEvent throws when end is before start', () async {
      final provider = CalendarProvider();
      expect(
        () => provider.addEvent(
          title: 'Bad Event',
          start: DateTime(2025, 1, 15, 11, 0),
          end: DateTime(2025, 1, 15, 10, 0),
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
        throwsArgumentError,
      );
    });

    test('addEvent throws when end equals start', () async {
      final provider = CalendarProvider();
      final sameTime = DateTime(2025, 1, 15, 10, 0);
      expect(
        () => provider.addEvent(
          title: 'Bad Event',
          start: sameTime,
          end: sameTime,
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
        throwsArgumentError,
      );
    });

    test('addEvent with all optional parameters', () async {
      final provider = CalendarProvider();
      await provider.addEvent(
        title: 'Full Event',
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
        repeatType: RepeatType.weekly,
        category: EventCategory.personal,
        reminder: ReminderOffset.min15,
        color: 0xFF0000FF,
        location: 'Office',
        locationLatitude: 55.75,
        locationLongitude: 37.62,
        description: 'Meeting',
        contacts: ['Alice'],
        attachments: ['file.pdf'],
        timeZoneOffset: 180,
        birthdayReminders: '0:9:0',
        dueDate: DateTime(2025, 1, 20),
      );

      expect(provider.events.length, 1);
      final event = provider.events.first;
      expect(event.title, 'Full Event');
      expect(event.location, 'Office');
      expect(event.description, 'Meeting');
      expect(event.contacts, ['Alice']);
    });
  });

  group('CalendarProvider — deleteEvent', () {
    test('deleteEvent removes event from Hive', () async {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      eventsBox.put('1', CalendarEvent(
        id: '1',
        title: 'To Delete',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      expect(provider.events.length, 1);
      await provider.deleteEvent('1');
      expect(provider.events.length, 0);
    });

    test('deleteEvent with non-existent id does not throw', () async {
      final provider = CalendarProvider();
      await provider.deleteEvent('nonexistent');
      expect(provider.events.length, 0);
    });
  });

  group('CalendarProvider — updateEvent', () {
    test('updateEvent saves changes', () async {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      final event = CalendarEvent(
        id: '1',
        title: 'Original',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      );
      eventsBox.put('1', event);

      event.title = 'Updated';
      await provider.updateEvent(event);

      expect(provider.getEventById('1')!.title, 'Updated');
    });
  });

  group('CalendarProvider — toggleTaskCompletion', () {
    test('toggleTaskCompletion toggles isCompleted', () async {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      final event = CalendarEvent(
        id: '1',
        title: 'Task',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.task,
        isCompleted: false,
      );
      eventsBox.put('1', event);

      expect(event.isCompleted, isFalse);
      await provider.toggleTaskCompletion(event);
      expect(event.isCompleted, isTrue);
      await provider.toggleTaskCompletion(event);
      expect(event.isCompleted, isFalse);
    });
  });

  group('CalendarProvider — eventsForDate', () {
    test('eventsForDate returns events for specific date', () {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      eventsBox.put('1', CalendarEvent(
        id: '1',
        title: 'Jan 15',
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      eventsBox.put('2', CalendarEvent(
        id: '2',
        title: 'Jan 16',
        start: DateTime(2025, 1, 16, 10, 0),
        end: DateTime(2025, 1, 16, 11, 0),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      final jan15Events = provider.eventsForDate(DateTime(2025, 1, 15));
      expect(jan15Events.length, 1);
      expect(jan15Events.first.title, 'Jan 15');
    });
  });

  group('CalendarProvider — cache invalidation', () {
    test('events cache is invalidated after addEvent', () async {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      expect(provider.events.length, 0);

      eventsBox.put('1', CalendarEvent(
        id: '1',
        title: 'Direct Put',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      await provider.addEvent(
        title: 'Via Provider',
        start: DateTime(2025, 1, 16),
        end: DateTime(2025, 1, 16, 1),
        repeatType: RepeatType.none,
        category: EventCategory.work,
      );

      expect(provider.events.length, 2);
    });
  });

  group('CalendarProvider — navigation methods', () {
    test('goPrevious day view moves back one day', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.day);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goPrevious();
      expect(provider.selectedDate, DateTime(2025, 1, 14));
    });

    test('goNext day view moves forward one day', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.day);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goNext();
      expect(provider.selectedDate, DateTime(2025, 1, 16));
    });

    test('goPrevious week view moves back 7 days', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.week);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goPrevious();
      expect(provider.selectedDate, DateTime(2025, 1, 8));
    });

    test('goNext week view moves forward 7 days', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.week);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goNext();
      expect(provider.selectedDate, DateTime(2025, 1, 22));
    });

    test('goPrevious month view moves to previous month', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.month);
      provider.setDate(DateTime(2025, 3, 15));
      provider.goPrevious();
      expect(provider.selectedDate.month, 2);
      expect(provider.selectedDate.year, 2025);
    });

    test('goNext month view moves to next month', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.month);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goNext();
      expect(provider.selectedDate.month, 2);
      expect(provider.selectedDate.year, 2025);
    });

    test('goPrevious year view moves to previous year', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.year);
      provider.setDate(DateTime(2025, 6, 15));
      provider.goPrevious();
      expect(provider.selectedDate.year, 2024);
    });

    test('goNext year view moves to next year', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.year);
      provider.setDate(DateTime(2025, 6, 15));
      provider.goNext();
      expect(provider.selectedDate.year, 2026);
    });

    test('goPrevious month handles year boundary', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.month);
      provider.setDate(DateTime(2025, 1, 15));
      provider.goPrevious();
      expect(provider.selectedDate.month, 12);
      expect(provider.selectedDate.year, 2024);
    });

    test('goNext month handles year boundary', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.month);
      provider.setDate(DateTime(2025, 12, 15));
      provider.goNext();
      expect(provider.selectedDate.month, 1);
      expect(provider.selectedDate.year, 2026);
    });

    test('goPrevious month clamps day for shorter months', () {
      final provider = CalendarProvider();
      provider.setView(CalendarViewType.month);
      provider.setDate(DateTime(2025, 3, 31));
      provider.goPrevious();
      expect(provider.selectedDate.day, 28);
      expect(provider.selectedDate.month, 2);
    });
  });

  group('CalendarProvider — visibleCategoryIndices', () {
    test('visibleCategoryIndices returns all when none hidden', () {
      final provider = CalendarProvider();
      final indices = provider.visibleCategoryIndices;
      expect(indices.length, EventCategory.values.length);
    });

    test('visibleCategoryIndices excludes hidden', () {
      final provider = CalendarProvider();
      provider.toggleCategory(EventCategory.work);
      final indices = provider.visibleCategoryIndices;
      expect(indices.contains(EventCategory.work.index), isFalse);
    });
  });

  group('CalendarProvider — event properties', () {
    test('getEventById returns event when exists', () {
      final provider = CalendarProvider();
      final eventsBox = Hive.box<CalendarEvent>('events');

      eventsBox.put('1', CalendarEvent(
        id: '1',
        title: 'Found',
        start: DateTime(2025, 1, 15),
        end: DateTime(2025, 1, 15, 1),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      final event = provider.getEventById('1');
      expect(event, isNotNull);
      expect(event!.title, 'Found');
    });
  });
}
