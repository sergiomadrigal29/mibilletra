import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String _periodicTaskName = 'periodicNotificationTask';

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

  Duration? get duration {
    return switch (this) {
      NotificationInterval.everyMinute => const Duration(minutes: 15),
      NotificationInterval.hourly => const Duration(hours: 1),
      NotificationInterval.every12Hours => const Duration(hours: 12),
      NotificationInterval.daily => const Duration(hours: 24),
      NotificationInterval.weekly => const Duration(days: 7),
      NotificationInterval.disabled => null,
    };
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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

  static Future<void> _crearCanalNotificacion() async {
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

  Future<void> _restaurarProgramacion() async {
    final interval = await NotificationInterval.load();
    if (interval != NotificationInterval.disabled) {
      await schedule(interval);
    }
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
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
      id,
      title ?? 'Mi Billetera',
      body ?? 'Recuerda ponerte al día con tu billetera',
      details,
    );
  }

  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: 'Mi Billetera',
      body: 'Notificación de prueba - funciona correctamente',
    );
  }

  Future<void> schedule(NotificationInterval interval) async {
    await cancelAll();

    if (interval == NotificationInterval.disabled) return;

    final duration = interval.duration;
    if (duration == null) return;

    await Workmanager().registerPeriodicTask(
      _periodicTaskName,
      _periodicTaskName,
      frequency: duration,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
    );
  }

  static Future<void> executePeriodicTask() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    await _crearCanalNotificacion();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios',
      channelDescription: 'Recordatorios para actualizar tu billetera',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      0,
      'Mi Billetera',
      'Recuerda ponerte al día con tu billetera',
      details,
    );
  }

  Future<bool> requestExactAlarmPermission() async => true;

  Future<void> cancelAll() async {
    await Workmanager().cancelByUniqueName(_periodicTaskName);
  }
}
