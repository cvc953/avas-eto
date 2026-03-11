import 'package:awesome_notifications/awesome_notifications.dart';
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

  String _eisenhowerQuadrantForTask(Tarea tarea) {
    final now = DateTime.now();
    final important =
        tarea.prioridad.toLowerCase() == 'alta' ||
        tarea.prioridad.toLowerCase() == 'media';
    final urgent = tarea.fechaVencimiento.isBefore(
      now.add(const Duration(days: 2)),
    );

    if (urgent && important) return 'Urgente e importante';
    if (!urgent && important) return 'No urgente pero importante';
    if (urgent && !important) return 'Urgente pero no importante';
    return 'No urgente y no importante';
  }

  String _coloredEisenhowerQuadrantForTask(Tarea tarea) {
    final text = _eisenhowerQuadrantForTask(tarea);
    final color = _eisenhowerColorForTask(tarea);
    final hex =
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    // Return an HTML fragment; some notification clients (Android) render
    // simple HTML tags. If not supported, the raw tags will be ignored.
    return '<font color="$hex">$text</font>';
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

  String _importanceLabelForTask(Tarea tarea) {
    final p = tarea.prioridad.toLowerCase();
    if (p == 'alta') return 'Alta';
    if (p == 'media') return 'Media';
    if (p == 'baja') return 'Baja';
    return tarea.prioridad;
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

  // Public wrappers for testability
  String getColoredQuadrantText(Tarea tarea) =>
      _coloredEisenhowerQuadrantForTask(tarea);
  String getOverdueText(Tarea tarea) => _overdueTextFor(tarea);

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
          // Try to use an HTML fragment for the colored quadrant label.
          body: _coloredEisenhowerQuadrantForTask(tarea),
          color: _eisenhowerColorForTask(tarea),
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': tarea.id},
        ),
        schedule: schedule,
      );
    }

    // If the task is already overdue, send an immediate notification
    // describing how long ago it expired and schedule a follow-up based
    // on importance.
    final now = DateTime.now();
    if (tarea.fechaVencimiento.isBefore(now)) {
      final overdueBody =
          '${_overdueTextFor(tarea)} — ${_coloredEisenhowerQuadrantForTask(tarea)}';
      final immediateId = base + 5000;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: immediateId,
          channelKey: 'tareas_channel',
          title: 'Tarea vencida: ${tarea.title}',
          body: '${_overdueTextFor(tarea)} — ${_importanceWithIcon(tarea)}',
          color: _eisenhowerColorForTask(tarea),
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': tarea.id},
        ),
      );

      // Schedule one follow-up reminder depending on priority
      int daysUntilFollowUp;
      switch (tarea.prioridad.toLowerCase()) {
        case 'alta':
          daysUntilFollowUp = 1; // cada dia
          break;
        case 'media':
          daysUntilFollowUp = 2;
          break;
        case 'baja':
          daysUntilFollowUp = 7;
          break;
        default:
          daysUntilFollowUp = 2;
      }

      final followUpDate = now.add(Duration(days: daysUntilFollowUp));
      final followUpId = base + 6000;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: followUpId,
          channelKey: 'tareas_channel',
          title: 'Recordatorio: ${tarea.title}',
          body: _coloredEisenhowerQuadrantForTask(tarea),
          color: _eisenhowerColorForTask(tarea),
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': tarea.id},
        ),
        schedule: NotificationCalendar.fromDate(date: followUpDate),
      );
    }
  }

  Future<void> cancelNotifications(Tarea tarea) async {
    final base = _baseIdFromTask(tarea);
    final ids =
        [1000, 2000, 3000, 4000, 5000, 6000].map((o) => base + o).toList();

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
