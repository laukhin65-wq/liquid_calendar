import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/repeat_type.dart';

/* ═══════════════════════════════════════════════════════════════════════
   Общая конфигурация канала.
   Объявлена на верхнем уровне, потому что её использует и фоновый колбэк
   (он в отдельном изоляте и не видит приватные поля класса).
   ═══════════════════════════════════════════════════════════════════ */
const _kNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'calendar_channel',
    'Calendar Notifications',
    channelDescription: 'Уведомления о событиях календаря',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@drawable/ic_notification',
  ),
);

/// Следующая дата срабатывания для повторяющегося события.
DateTime _addRepeat(DateTime d, RepeatType repeatType) {
  switch (repeatType) {
    case RepeatType.weekly:
      return d.add(const Duration(days: 7));
    case RepeatType.monthly:
      return DateTime(d.year, d.month + 1, d.day, d.hour, d.minute);
    case RepeatType.yearly:
      return DateTime(d.year + 1, d.month, d.day, d.hour, d.minute);
    case RepeatType.daily:
      return d.add(const Duration(days: 1));
    case RepeatType.none:
      return d.add(const Duration(days: 1));
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   TOP-LEVEL CALLBACK — выполняется в ФОНОВОМ ИЗОЛЯТЕ.
   android_alarm_manager_plus запускает новый Dart-изолят, поэтому плагин
   надо инициализировать заново.
   ═══════════════════════════════════════════════════════════════════ */
@pragma('vm:entry-point')
Future<void> onAlarmFired(int id, Map<String, dynamic> params) async {
  // 1. Инициализируем плагин (новый изолят — без состояния основного)
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
      settings: const InitializationSettings(android: androidInit));

  // 2. Достаём данные уведомления
  final title = params['title'] as String? ?? 'Напоминание';
  final body = params['body'] as String? ?? '';

  // 3. show() — работает даже на Vivo/Xiaomi в фоне
  await plugin.show(
      id: id, title: title, body: body, notificationDetails: _kNotificationDetails);

  // 4. Повтор: планируем напоминание для СЛЕДУЮЩЕГО вхождения.
  //    Раньше тут всегда было +24 ч → недельные/месячные события
  //    напоминали бы каждый день. Теперь шаг зависит от repeatType.
  final repeatTypeIndex = params['repeatType'] as int? ?? 0;
  final repeatType = RepeatType.values[repeatTypeIndex];
  final fireMillis = params['fireMillis'] as int?;
  if (repeatType != RepeatType.none && fireMillis != null) {
    final current = DateTime.fromMillisecondsSinceEpoch(fireMillis);
    final next = _addRepeat(current, repeatType);

    final nextParams = Map<String, dynamic>.from(params)
      ..['fireMillis'] = next.millisecondsSinceEpoch;

    await AndroidAlarmManager.oneShotAt(
      next,
      id,
      onAlarmFired,
      exact: true,
      wakeup: true,
      alarmClock: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: nextParams,
    );
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   NotificationService
   ═══════════════════════════════════════════════════════════════════ */
class NotificationService {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 1));
  static final _plugin = FlutterLocalNotificationsPlugin();

  /* ── Init (вызвать один раз в main()) ────────────────────────────── */
  static Future<void> init() async {
    // Timezone
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin
        .initialize(settings: const InitializationSettings(android: androidInit));

    // android_alarm_manager_plus
    await AndroidAlarmManager.initialize();

    // Разрешения (Android 13+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    _log.i('NotificationService initialized (tz=${tzInfo.identifier})');
  }

  /* ── Мгновенное уведомление ──────────────────────────────────────── */
  static Future<void> show(int id, String title, String body) async {
    await _plugin.show(
        id: id, title: title, body: body, notificationDetails: _kNotificationDetails);
    _log.i('Мгновенное уведомление #$id показано');
  }

  /* ── Запланированное уведомление ─────────────────────────────────── */
  /// Использует [AndroidAlarmManager] + [show] вместо zonedSchedule.
  /// alarmClock:true → AlarmManager.setAlarmClock() — наивысший приоритет,
  /// обходит Doze И «убийц батареи» от вендоров (Vivo, Xiaomi, Samsung…).
  ///
  /// [repeat] оставлен для обратной совместимости (true → daily).
  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    bool repeat = false,
    int repeatType = 0,
  }) async {
    final type = RepeatType.values[repeatType];
    // Совместимость: если передали только repeat=true — считаем «ежедневно».
    final effectiveType = (repeat && type == RepeatType.none) ? RepeatType.daily : type;

    final now = DateTime.now();
    var target = scheduledDate;

    // Время уже прошло?
    if (target.isBefore(now)) {
      if (effectiveType == RepeatType.none) {
        // Разовое напоминание в прошлом → показываем сразу и выходим.
        // (Раньше код сдвигал на +1 день — уведомление приходило уже
        //  ПОСЛЕ события, в бессмысленное время.)
        await show(id, title, body);
        return;
      }
      // Повторяющееся → прокручиваем до ближайшего будущего вхождения.
      while (target.isBefore(now)) {
        target = _addRepeat(target, effectiveType);
      }
    }

    try {
      final ok = await AndroidAlarmManager.oneShotAt(
        target,
        id,
        onAlarmFired,
        exact: true,
        wakeup: true,
        alarmClock: true,
        allowWhileIdle: true,
        // ВАЖНО: переживает перезагрузку телефона (раньше было false —
        // напоминание терялось при ребуте до срабатывания).
        rescheduleOnReboot: true,
        params: {
          'title': title,
          'body': body,
          'repeatType': effectiveType.index,
          'fireMillis': target.millisecondsSinceEpoch,
        },
      );

      if (ok) {
        _log.i(
          'Уведомление #$id запланировано на $target (repeatType=$effectiveType)',
        );
      } else {
        _log.e('AndroidAlarmManager.oneShotAt вернул false для #$id');
      }
    } catch (e, st) {
      _log.e('Ошибка планирования #$id', error: e, stackTrace: st);
    }
  }

  /* ── Отмена ──────────────────────────────────────────────────────── */
  static Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _plugin.cancel(id: id);
  }
}
