import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/tarea.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tzdata.initializeTimeZones();

    // Crear canal de notificación con sonido
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tareas_channel',
      'Notificaciones de Tareas',
      description: 'Canal para notificaciones de tareas',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Solicitar permisos de notificaciones en Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Solicitar permisos para alarmas exactas en Android 12+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  /// Envía múltiples notificaciones según la prioridad de la tarea
  /// Alta: 1 día antes, 1 hora antes, 30 minutos antes
  /// Media: 3 horas antes, 1 hora antes
  /// Baja: 1 día antes
  Future<void> notifyTaskCreated(Tarea tarea) async {
    switch (tarea.prioridad.toLowerCase()) {
      case 'alta':
        // 1 día antes
        await _scheduleNotification(
          tarea,
          -1440,
          'Recordatorio: ${tarea.title} (Prioridad Alta)',
        );
        // 1 hora antes
        await _scheduleNotification(
          tarea,
          -60,
          'Recordatorio: ${tarea.title} (Prioridad Alta)',
        );
        // 30 minutos antes
        await _scheduleNotification(
          tarea,
          -30,
          'Recordatorio: ${tarea.title} (Prioridad Alta)',
        );
        break;
      case 'media':
        // 3 horas antes
        await _scheduleNotification(
          tarea,
          -180,
          'Recordatorio: ${tarea.title} (Prioridad Media)',
        );
        // 1 hora antes
        await _scheduleNotification(
          tarea,
          -60,
          'Recordatorio: ${tarea.title} (Prioridad Media)',
        );
        break;
      case 'baja':
        // 1 día antes
        await _scheduleNotification(
          tarea,
          -1440,
          'Recordatorio: ${tarea.title} (Prioridad Baja)',
        );
        break;
      default:
        // Default: 1 hora antes
        await _scheduleNotification(tarea, -60, 'Recordatorio: ${tarea.title}');
    }
  }

  /// Programa una notificación para una hora específica
  Future<void> _scheduleNotification(
    Tarea tarea,
    int delayMinutes,
    String titulo,
  ) async {
    final scheduledDate = tarea.fechaVencimiento.add(
      Duration(minutes: delayMinutes),
    );

    // No programar si la fecha ya pasó
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'tareas_channel',
      'Notificaciones de Tareas',
      channelDescription: 'Canal para notificaciones de tareas',
      importance: _getImportanceByPriority(tarea.prioridad),
      priority: _getPriorityByPriority(tarea.prioridad),
      color: Color(tarea.color.value),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'tareas_channel',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        tarea.hashCode + delayMinutes,
        titulo,
        'Prioridad: ${tarea.prioridad}\n${tarea.descripcion}',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error programando notificación: $e');
    }
  }

  /// Obtiene el nivel de importancia según la prioridad
  Importance _getImportanceByPriority(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Importance.max;
      case 'media':
        return Importance.defaultImportance;
      case 'baja':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Obtiene el nivel de prioridad según la prioridad
  Priority _getPriorityByPriority(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Priority.high;
      case 'media':
        return Priority.defaultPriority;
      case 'baja':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Cancela todas las notificaciones de una tarea
  Future<void> cancelNotifications(Tarea tarea) async {
    // Cancelar las 3 notificaciones posibles (para los delays: -1440, -180, -60, -30)
    await _flutterLocalNotificationsPlugin.cancel(tarea.hashCode - 1440);
    await _flutterLocalNotificationsPlugin.cancel(tarea.hashCode - 180);
    await _flutterLocalNotificationsPlugin.cancel(tarea.hashCode - 60);
    await _flutterLocalNotificationsPlugin.cancel(tarea.hashCode - 30);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
