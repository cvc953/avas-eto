import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'notifications_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _initialize();
  }

  Future<void> _initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'tareas_channel',
        channelName: 'Notificaciones de Tareas',
        channelDescription: 'Canal para notificaciones de tareas',
        defaultColor: Colors.deepPurple,
        importance: NotificationImportance.Max,
        playSound: true,
        enableVibration: true,
      ),
    ], debug: false);
  }

  int _baseIdFromTask(Tarea tarea) {
    return tarea.id.hashCode & 0x7fffffff;
  }

  Future<void> notifyTaskCreated(Tarea tarea) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) return;

    final base = _baseIdFromTask(tarea);

    final Map<int, int> offsets = {
      -1440: 1000,
      -180: 2000,
      -60: 3000,
      -30: 4000,
    };

    List<int> chosenOffsets;
    switch (tarea.prioridad.toLowerCase()) {
      case 'alta':
        chosenOffsets = [-1440, -60, -30];
        break;
      case 'media':
        chosenOffsets = [-180, -60];
        break;
      case 'baja':
        chosenOffsets = [-1440];
        break;
      default:
        chosenOffsets = [-60];
    }

    for (var minutesOffset in chosenOffsets) {
      final scheduled = tarea.fechaVencimiento.add(
        Duration(minutes: minutesOffset),
      );
      if (scheduled.isBefore(DateTime.now())) continue;

      final id = base + (offsets[minutesOffset] ?? 0);

      final schedule = NotificationCalendar.fromDate(date: scheduled);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'tareas_channel',
          title: 'Recordatorio: ${tarea.title}',
          body: 'Prioridad: ${tarea.prioridad}\n${tarea.descripcion}',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': tarea.id},
        ),
        schedule: schedule,
      );
    }
  }

  Future<void> cancelNotifications(Tarea tarea) async {
    final base = _baseIdFromTask(tarea);
    final ids = [1000, 2000, 3000, 4000].map((o) => base + o).toList();
    // Cancel any scheduled and delivered notifications for these ids.
    for (var id in ids) {
      try {
        await AwesomeNotifications().cancelSchedule(id);
      } catch (_) {}
      try {
        await AwesomeNotifications().cancel(id);
      } catch (_) {}
    }
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    await AwesomeNotifications().cancelAll();
  }
}
