import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/calendar_provider.dart';
import 'providers/theme_provider.dart';
import 'data/models/calendar_event.dart';
import 'screens/calendar_screen.dart';
import 'services/widget_action_service.dart';
import 'theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const _actionsChannel = MethodChannel('com.example.liquid_calendar/widget_actions');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru_RU', null);

  await Hive.initFlutter();
  Hive.registerAdapter(CalendarEventAdapter());
  await Hive.openBox<CalendarEvent>('events');
  await Hive.openBox('settings');

  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _actionsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final arguments = call.arguments as Map?;
        if (arguments != null) {
          final action = arguments['action'] as String;
          final eventId = arguments['eventId'] as String;
          _handleWidgetAction(action, eventId);
        }
      }
    });

    _signalWidgetReady();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingAction();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingAction();
    }
  }

  Future<void> _signalWidgetReady() async {
    try {
      await _actionsChannel.invokeMethod('widgetReady');
    } catch (e) {
      debugPrint('Error signaling widget ready: $e');
    }
  }

  Future<void> _checkPendingAction() async {
    if (_checking) return;
    _checking = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final action = prefs.getString('pending_action');
      if (action != null && mounted) {
        final eventId = prefs.getString('pending_event_id') ?? '';
        await prefs.remove('pending_action');
        await prefs.remove('pending_event_id');
        _handleWidgetAction(action, eventId);
      }
    } catch (e) {
      debugPrint('Error checking pending action: $e');
    } finally {
      _checking = false;
    }
  }

  void _handleWidgetAction(String action, String eventId) {
    if (!mounted) return;
    WidgetActionService.handleAction(action, eventId, navigatorKey: navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LIFE — Календарь жизни',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      home: const CalendarScreen(),
    );
  }
}
