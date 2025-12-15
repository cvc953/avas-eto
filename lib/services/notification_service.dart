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

  /// Envía notificación según la prioridad de la tarea
  /// Alta: inmediata
  /// Media: 1 hora antes
  /// Baja: 1 día antes
  Future<void> notifyTaskCreated(Tarea tarea) async {
    final delayMinutes = _getDelayByPriority(tarea.prioridad);

    if (delayMinutes == 0) {
      // Notificación inmediata para Alta
      await _showNotification(tarea);
    } else {
      // Notificación programada para Media y Baja
      await _scheduleNotification(tarea, delayMinutes);
    }
  }

  /// Obtiene el delay en minutos según la prioridad
  int _getDelayByPriority(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return 0; // Inmediata
      case 'media':
        return -60; // 1 hora antes del vencimiento
      case 'baja':
        return -1440; // 1 día antes del vencimiento
      default:
        return -60;
    }
  }

  /// Muestra una notificación inmediata
  Future<void> _showNotification(Tarea tarea) async {
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

    await _flutterLocalNotificationsPlugin.show(
      tarea.hashCode,
      'Nueva Tarea: ${tarea.title}',
      'Prioridad: ${tarea.prioridad}\n${tarea.descripcion}',
      details,
    );
  }

  /// Programa una notificación para una hora específica
  Future<void> _scheduleNotification(Tarea tarea, int delayMinutes) async {
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      tarea.hashCode,
      'Recordatorio: ${tarea.title}',
      'Prioridad: ${tarea.prioridad}\n${tarea.descripcion}',
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  /// Cancela una notificación
  Future<void> cancelNotification(Tarea tarea) async {
    await _flutterLocalNotificationsPlugin.cancel(tarea.hashCode);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
