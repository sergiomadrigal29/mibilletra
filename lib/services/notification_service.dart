import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

enum NotificationInterval {
  disabled('Desactivado'),
  everyMinute('Cada 15 minuto'),
  hourly('Cada hora'),
  every12Hours('Cada 12 horas'),
  daily('Cada día'),
  weekly('Cada semana');

  final String label;
  const NotificationInterval(this.label);

  static const _prefsKey = 'notification_interval';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, name);
  }

  static Future<NotificationInterval> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    return NotificationInterval.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationInterval.disabled,
    );
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    await _crearCanalNotificacion();
    await requestNotificationPermission();
    try {
      await _restaurarProgramacion();
    } catch (e) {
      debugPrint('Error restoring notification schedule: $e');
    }
  }

  Future<void> _crearCanalNotificacion() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final channel = AndroidNotificationChannel(
      'reminder_channel',
      'Recordatorios',
      description: 'Recordatorios para actualizar tu billetera',
      importance: Importance.high,
    );
    await android.createNotificationChannel(channel);
  }

  Future<void> requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  Future<bool> _requestExactAlarmPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestExactAlarmsPermission();
    return granted == true;
  }

  Future<void> _restaurarProgramacion() async {
    final interval = await NotificationInterval.load();
    if (interval != NotificationInterval.disabled) {
      await schedule(interval);
    }
  }

  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios',
      channelDescription: 'Recordatorios para actualizar tu billetera',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      999,
      'Mi Billetera',
      'Notificación de prueba - funciona correctamente',
      details,
    );
  }

  Future<void> _programarConExact(
    int id,
    NotificationDetails details,
    Future<void> Function() programarExact,
    Future<void> Function() programarInexact,
  ) async {
    try {
      await programarExact();
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await programarInexact();
      } else {
        rethrow;
      }
    }
  }

  Future<void> schedule(NotificationInterval interval) async {
    await cancelAll();

    if (interval == NotificationInterval.disabled) return;

    const title = 'Mi Billetera';
    const body = 'Recuerda ponerte al día con tu billetera';
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios',
      channelDescription: 'Recordatorios para actualizar tu billetera',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);

    switch (interval) {
      case NotificationInterval.everyMinute:
        await _programarConExact(
          0,
          details,
          () => _plugin.periodicallyShowWithDuration(
            0,
            title,
            body,
            const Duration(minutes: 15),
            details,
          ),
          () => _plugin.periodicallyShowWithDuration(
            0,
            title,
            body,
            const Duration(minutes: 15),
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
          ),
        );
      case NotificationInterval.hourly:
        await _programarConExact(
          1,
          details,
          () => _plugin.periodicallyShowWithDuration(
            1,
            title,
            body,
            const Duration(hours: 1),
            details,
          ),
          () => _plugin.periodicallyShowWithDuration(
            1,
            title,
            body,
            const Duration(hours: 1),
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
          ),
        );
      case NotificationInterval.every12Hours:
        await _programarConExact(
          2,
          details,
          () => _plugin.periodicallyShowWithDuration(
            2,
            title,
            body,
            const Duration(hours: 12),
            details,
          ),
          () => _plugin.periodicallyShowWithDuration(
            2,
            title,
            body,
            const Duration(hours: 12),
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
          ),
        );
      case NotificationInterval.daily:
        final dailyTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          9,
          0,
        );
        await _plugin.zonedSchedule(
          3,
          title,
          body,
          dailyTime.isBefore(now)
              ? dailyTime.add(const Duration(days: 1))
              : dailyTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      case NotificationInterval.weekly:
        final weeklyTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          9,
          0,
        );
        await _plugin.zonedSchedule(
          4,
          title,
          body,
          weeklyTime.isBefore(now)
              ? weeklyTime.add(const Duration(days: 7))
              : weeklyTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      case NotificationInterval.disabled:
        break;
    }
  }

  Future<bool> requestExactAlarmPermission() => _requestExactAlarmPermission();

  Future<void> cancelAll() async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(i);
    }
  }
}
