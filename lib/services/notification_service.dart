import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import 'notifications_settings.dart';

class NotificationService {
  static const int _driveUploadNotificationId = 9042;
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
      NotificationChannel(
        channelKey: 'drive_upload_channel',
        channelName: 'Subidas a Google Drive',
        channelDescription: 'Estado y progreso de archivos en subida',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        playSound: false,
        enableVibration: false,
      ),
    ], debug: false);
  }

  int _baseIdFromTask(Tarea tarea) {
    return tarea.id.hashCode & 0x7fffffff;
  }

  String _importanceLabelForTask(Tarea tarea) {
    switch (tarea.prioridad.toLowerCase()) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'baja':
        return 'Baja';
      default:
        return tarea.prioridad;
    }
  }

  String _importanceIconHtml(Tarea tarea) {
    final color = _eisenhowerColorForTask(tarea);
    final hex =
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    return '<font color="$hex">●</font>';
  }

  String _importanceWithIcon(Tarea tarea) {
    return '${_importanceIconHtml(tarea)} ${_importanceLabelForTask(tarea)}';
  }

  String _overdueTextFor(Tarea tarea) {
    final now = DateTime.now();
    final diff = now.difference(tarea.fechaVencimiento);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'Venció hace ${m == 1 ? '1 minuto' : '$m minutos'}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'Venció hace ${h == 1 ? '1 hora' : '$h horas'}';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return 'Venció hace ${d == 1 ? '1 día' : '$d días'}';
    }
    final w = (diff.inDays / 7).floor();
    return 'Venció hace ${w == 1 ? '1 semana' : '$w semanas'}';
  }

  int _importanceWeightForTask(Tarea tarea) {
    switch (tarea.prioridad.toLowerCase()) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baja':
        return 1;
      default:
        return 1;
    }
  }

  int _urgencyDaysRemainingWeightForTask(Tarea tarea, DateTime referenceNow) {
    final daysRemaining = tarea.fechaInicio.difference(referenceNow).inDays;
    if (daysRemaining <= 0) return 3;
    if (daysRemaining == 1) return 2;
    if (daysRemaining <= 3) return 1;
    return 0;
  }

  int _procrastinationWeightForTask(Tarea tarea) {
    return tarea.vecesPospuesta.clamp(0, 3);
  }

  int _shortDurationBonusForTask(Tarea tarea) {
    return tarea.duracionMinutos <= 30 ? 1 : 0;
  }

  int _focusScoreForTask(Tarea tarea, DateTime referenceNow) {
    final importanciaUsuario = _importanceWeightForTask(tarea);
    final urgenciaDiasRestantes = _urgencyDaysRemainingWeightForTask(
      tarea,
      referenceNow,
    );
    final procrastinacion = _procrastinationWeightForTask(tarea);
    final duracionCortaBonus = _shortDurationBonusForTask(tarea);

    return (importanciaUsuario * 3) +
        (urgenciaDiasRestantes * 2) +
        (procrastinacion * 2) +
        duracionCortaBonus;
  }

  List<DateTime> _startReminderMomentsForTask(Tarea tarea) {
    final inicio = tarea.fechaInicio;
    return [
      inicio.subtract(const Duration(days: 1)),
      inicio.subtract(const Duration(hours: 1)),
      inicio.subtract(const Duration(minutes: 30)),
      inicio.subtract(const Duration(minutes: 10)),
      inicio,
    ];
  }

  // Public wrappers for testability
  String getImportanceText(Tarea tarea) => _importanceWithIcon(tarea);
  String getOverdueText(Tarea tarea) => _overdueTextFor(tarea);
  int getFocusScore(Tarea tarea, {DateTime? referenceNow}) =>
      _focusScoreForTask(tarea, referenceNow ?? DateTime.now());
  List<DateTime> getStartReminderMoments(Tarea tarea) =>
      _startReminderMomentsForTask(tarea);

  Color _eisenhowerColorForTask(Tarea tarea) {
    final now = DateTime.now();
    final important =
        tarea.prioridad.toLowerCase() == 'alta' ||
        tarea.prioridad.toLowerCase() == 'media';
    final urgent = tarea.fechaVencimiento.isBefore(
      now.add(const Duration(days: 2)),
    );

    if (urgent && important) return const Color(0xFFFF5F6D);
    if (!urgent && important) return const Color(0xFFFFBC1F);
    if (urgent && !important) return const Color(0xFF4E7BFF);
    return const Color(0xFF00D4B5);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Color color,
    required String taskId,
    NotificationSchedule? schedule,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'tareas_channel',
        title: title,
        body: body,
        color: color,
        notificationLayout: NotificationLayout.Default,
        payload: {'taskId': taskId},
      ),
      schedule: schedule,
    );
  }

  Future<void> _scheduleDailyOverdueReminder(
    Tarea tarea,
    DateTime firstDate,
  ) async {
    final id = _baseIdFromTask(tarea) + 7000;
    final color = _eisenhowerColorForTask(tarea);
    final body =
        '${_importanceWithIcon(tarea)} · Foco hoy: ${_focusScoreForTask(tarea, DateTime.now())}';

    if (!kIsWeb && Platform.isAndroid) {
      final expression =
          '${firstDate.second} ${firstDate.minute} ${firstDate.hour} * * ? *';
      await _scheduleNotification(
        id: id,
        title: 'Sigue pendiente: ${tarea.title}',
        body: body,
        color: color,
        taskId: tarea.id,
        schedule: NotificationAndroidCrontab(
          initialDateTime: firstDate,
          crontabExpression: expression,
          repeats: true,
          preciseAlarm: true,
        ),
      );
      return;
    }

    await _scheduleNotification(
      id: id,
      title: 'Sigue pendiente: ${tarea.title}',
      body: body,
      color: color,
      taskId: tarea.id,
      schedule: NotificationCalendar(
        hour: firstDate.hour,
        minute: firstDate.minute,
        second: firstDate.second,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> notifyTaskCreated(Tarea tarea) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) return;

    final base = _baseIdFromTask(tarea);
    final now = DateTime.now();
    final reminderMoments = _startReminderMomentsForTask(tarea);
    final reminderIds = [1000, 2000, 3000, 4000, 5000];

    for (var index = 0; index < reminderMoments.length; index++) {
      final scheduled = reminderMoments[index];
      if (scheduled.isBefore(now)) continue;

      await _scheduleNotification(
        id: base + reminderIds[index],
        title: 'Recordatorio: ${tarea.title}',
        body: _importanceWithIcon(tarea),
        color: _eisenhowerColorForTask(tarea),
        taskId: tarea.id,
        schedule: NotificationCalendar.fromDate(
          date: scheduled,
          preciseAlarm: true,
        ),
      );
    }

    final oneHourAfterEnd = tarea.fechaVencimiento.add(
      const Duration(hours: 1),
    );
    if (!tarea.completada) {
      if (oneHourAfterEnd.isAfter(now)) {
        await _scheduleNotification(
          id: base + 6000,
          title: 'Tarea vencida: ${tarea.title}',
          body:
              '${_importanceWithIcon(tarea)} · Foco hoy: ${_focusScoreForTask(tarea, now)}',
          color: _eisenhowerColorForTask(tarea),
          taskId: tarea.id,
          schedule: NotificationCalendar.fromDate(
            date: oneHourAfterEnd,
            preciseAlarm: true,
          ),
        );
      } else {
        await _scheduleNotification(
          id: base + 8000,
          title: 'Tarea vencida: ${tarea.title}',
          body:
              '${_overdueTextFor(tarea)} · ${_importanceWithIcon(tarea)} · Foco hoy: ${_focusScoreForTask(tarea, now)}',
          color: _eisenhowerColorForTask(tarea),
          taskId: tarea.id,
        );
      }

      final firstDailyFollowUp =
          oneHourAfterEnd.isAfter(now)
              ? oneHourAfterEnd.add(const Duration(days: 1))
              : now.add(const Duration(days: 1));
      await _scheduleDailyOverdueReminder(tarea, firstDailyFollowUp);
    }
  }

  Future<void> cancelNotifications(Tarea tarea) async {
    final base = _baseIdFromTask(tarea);
    final ids =
        [
          1000,
          2000,
          3000,
          4000,
          5000,
          6000,
          7000,
          8000,
        ].map((o) => base + o).toList();

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

  Future<void> showDriveUploadStatus({
    required String fileName,
    required int completed,
    required int total,
  }) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled || total <= 0) return;

    final progress = ((completed / total) * 100).clamp(0, 100).toDouble();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _driveUploadNotificationId,
        channelKey: 'drive_upload_channel',
        title: 'Subiendo adjuntos a Google Drive',
        body: '$completed de $total completados. Archivo actual: $fileName',
        category: NotificationCategory.Progress,
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress,
        locked: true,
      ),
    );
  }

  Future<void> completeDriveUploadStatus(int total) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _driveUploadNotificationId,
        channelKey: 'drive_upload_channel',
        title: 'Subida completada',
        body: 'Se subieron $total adjuntos a Google Drive.',
        category: NotificationCategory.Progress,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> failDriveUploadStatus(String message) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _driveUploadNotificationId,
        channelKey: 'drive_upload_channel',
        title: 'Subida incompleta a Google Drive',
        body: message,
        category: NotificationCategory.Status,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> cancelDriveUploadStatus() async {
    await AwesomeNotifications().cancel(_driveUploadNotificationId);
  }
}
