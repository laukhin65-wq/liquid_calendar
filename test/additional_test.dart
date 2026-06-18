import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:liquid_calendar/data/models/calendar_event.dart';
import 'package:liquid_calendar/data/models/contact_model.dart';
import 'package:liquid_calendar/data/models/location_model.dart';
import 'package:liquid_calendar/data/models/event_category.dart';
import 'package:liquid_calendar/data/models/repeat_type.dart';
import 'package:liquid_calendar/data/models/life_statistics.dart';
import 'package:liquid_calendar/services/life_statistics_service.dart';
import 'package:liquid_calendar/models/schedule_item.dart';
import 'package:liquid_calendar/providers/theme_provider.dart';
import 'package:liquid_calendar/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final widgetChannel = MethodChannel('com.example.liquid_calendar/widget');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(widgetChannel, (call) async => null);

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

  group('ContactModel', () {
    test('fromMap creates model', () {
      final model = ContactModel.fromMap({
        'name': 'Alice',
        'phone': '+79001234567',
        'email': 'alice@example.com',
        'company': 'Acme',
      });
      expect(model.name, 'Alice');
      expect(model.phone, '+79001234567');
      expect(model.email, 'alice@example.com');
      expect(model.company, 'Acme');
    });

    test('fromMap with missing fields', () {
      final model = ContactModel.fromMap({'name': 'Bob'});
      expect(model.name, 'Bob');
      expect(model.phone, isNull);
      expect(model.email, isNull);
      expect(model.company, isNull);
    });

    test('fromString parses pipe-separated', () {
      final model = ContactModel.fromString('Charlie | +79001112233');
      expect(model.name, 'Charlie');
      expect(model.phone, '+79001112233');
    });

    test('fromString without phone', () {
      final model = ContactModel.fromString('Dave');
      expect(model.name, 'Dave');
      expect(model.phone, isNull);
    });

    test('toMap roundtrip', () {
      const original = ContactModel(
        name: 'Eve',
        phone: '+79003334455',
        email: 'eve@test.com',
        company: 'Corp',
      );
      final map = original.toMap();
      final restored = ContactModel.fromMap(map);
      expect(restored.name, original.name);
      expect(restored.phone, original.phone);
      expect(restored.email, original.email);
      expect(restored.company, original.company);
    });

    test('toDisplayString includes all fields', () {
      const model = ContactModel(
        name: 'Frank',
        phone: '+79005556677',
        email: 'frank@test.com',
        company: 'Inc',
      );
      final display = model.toDisplayString();
      expect(display, contains('Frank'));
      expect(display, contains('+79005556677'));
      expect(display, contains('frank@test.com'));
      expect(display, contains('Inc'));
    });

    test('toDisplayString without optional fields', () {
      const model = ContactModel(name: 'Grace');
      final display = model.toDisplayString();
      expect(display, 'Grace');
    });
  });

  group('LocationModel', () {
    test('fromMap creates model', () {
      final model = LocationModel.fromMap({
        'name': 'Office',
        'address': '123 Main St',
        'latitude': 55.75,
        'longitude': 37.62,
      });
      expect(model.name, 'Office');
      expect(model.address, '123 Main St');
      expect(model.latitude, 55.75);
      expect(model.longitude, 37.62);
    });

    test('fromMap with missing fields', () {
      final model = LocationModel.fromMap({'name': 'Park'});
      expect(model.name, 'Park');
      expect(model.address, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });

    test('toMap roundtrip', () {
      const original = LocationModel(
        name: 'Cafe',
        address: '456 Oak Ave',
        latitude: 55.76,
        longitude: 37.63,
      );
      final map = original.toMap();
      final restored = LocationModel.fromMap(map);
      expect(restored.name, original.name);
      expect(restored.address, original.address);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });

    test('mapUrl with coordinates', () {
      const model = LocationModel(
        name: 'Test',
        latitude: 55.75,
        longitude: 37.62,
      );
      expect(model.mapUrl, contains('55.75'));
      expect(model.mapUrl, contains('37.62'));
    });

    test('mapUrl without coordinates', () {
      const model = LocationModel(name: 'Unknown Place');
      expect(model.mapUrl, contains('Unknown'));
    });

    test('geoUri with coordinates', () {
      const model = LocationModel(
        name: 'Test',
        latitude: 55.75,
        longitude: 37.62,
      );
      expect(model.geoUri, startsWith('geo:'));
      expect(model.geoUri, contains('55.75'));
    });

    test('geoUri without coordinates', () {
      const model = LocationModel(name: 'Somewhere');
      expect(model.geoUri, startsWith('geo:'));
    });

    test('toDisplayString includes address and coords', () {
      const model = LocationModel(
        name: 'HQ',
        address: '789 Pine Rd',
        latitude: 55.77,
        longitude: 37.64,
      );
      final display = model.toDisplayString();
      expect(display, contains('HQ'));
      expect(display, contains('789 Pine Rd'));
      expect(display, contains('55.77'));
    });

    test('toDisplayString without optional fields', () {
      const model = LocationModel(name: 'Simple');
      final display = model.toDisplayString();
      expect(display, contains('Simple'));
    });
  });

  group('ScheduleBuilder', () {
    test('build returns empty for empty events', () {
      final result = ScheduleBuilder.build([]);
      expect(result, isEmpty);
    });

    test('build creates items for single event', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Meeting',
          start: DateTime(2025, 1, 15, 10, 0),
          end: DateTime(2025, 1, 15, 11, 0),
          color: 0,
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
      ];
      final result = ScheduleBuilder.build(events);
      expect(result.isNotEmpty, true);
      expect(result.any((item) => item is EventItem), true);
    });

    test('build creates month headers', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Event',
          start: DateTime(2025, 1, 15, 10, 0),
          end: DateTime(2025, 1, 15, 11, 0),
          color: 0,
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
      ];
      final result = ScheduleBuilder.build(events);
      expect(result.any((item) => item is MonthHeaderItem), true);
    });

    test('build sorts events by start time', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Later',
          start: DateTime(2025, 1, 15, 14, 0),
          end: DateTime(2025, 1, 15, 15, 0),
          color: 0,
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
        CalendarEvent(
          id: '2',
          title: 'Earlier',
          start: DateTime(2025, 1, 15, 10, 0),
          end: DateTime(2025, 1, 15, 11, 0),
          color: 0,
          repeatType: RepeatType.none,
          category: EventCategory.work,
        ),
      ];
      final result = ScheduleBuilder.build(events);
      final eventItems = result.whereType<EventItem>().toList();
      expect(eventItems.first.event.title, 'Earlier');
      expect(eventItems.last.event.title, 'Later');
    });
  });

  group('ThemeProvider', () {
    test('default choice is system', () {
      final provider = ThemeProvider();
      expect(provider.choice, AppThemeChoice.system);
    });

    test('setChoice updates choice', () {
      final provider = ThemeProvider();
      provider.setChoice(AppThemeChoice.dark);
      expect(provider.choice, AppThemeChoice.dark);
    });

    test('isGlass returns true for glass themes', () {
      final provider = ThemeProvider();
      provider.setChoice(AppThemeChoice.glassLight);
      expect(provider.isGlass, isTrue);
    });

    test('isGlass returns false for non-glass themes', () {
      final provider = ThemeProvider();
      provider.setChoice(AppThemeChoice.light);
      expect(provider.isGlass, isFalse);
    });

    test('themeMode returns correct mode', () {
      final provider = ThemeProvider();
      provider.setChoice(AppThemeChoice.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });
  });

  group('AppTheme', () {
    test('light theme has light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme has dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('light glass theme has transparent scaffold', () {
      final theme = AppTheme.light(glass: true);
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
    });

    test('dark glass theme has transparent scaffold', () {
      final theme = AppTheme.dark(glass: true);
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
    });
  });

  group('LifeStatisticsService', () {
    test('calculate returns empty stats when no events', () {
      final service = LifeStatisticsService();
      final stats = service.calculate();
      expect(stats.allTime.totalEvents, 0);
      expect(stats.allTime.totalTasks, 0);
      expect(stats.allTime.completedTasks, 0);
    });

    test('getEventsForDate returns events for date', () {
      final box = Hive.box<CalendarEvent>('events');
      box.put('1', CalendarEvent(
        id: '1',
        title: 'Test',
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      final service = LifeStatisticsService();
      final events = service.getEventsForDate(DateTime(2025, 1, 15));
      expect(events.length, 1);
    });

    test('getEventsInRange returns events in range', () {
      final box = Hive.box<CalendarEvent>('events');
      box.put('1', CalendarEvent(
        id: '1',
        title: 'Test',
        start: DateTime(2025, 1, 15, 10, 0),
        end: DateTime(2025, 1, 15, 11, 0),
        color: 0,
        repeatType: RepeatType.none,
        category: EventCategory.work,
      ));

      final service = LifeStatisticsService();
      final events = service.getEventsInRange(
        DateTime(2025, 1, 14),
        DateTime(2025, 1, 16),
      );
      expect(events.length, 1);
    });
  });
}
