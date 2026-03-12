import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/completion_behavior_event.dart';
import '../models/tarea.dart';
import 'adaptive_scheduler.dart';
import 'completion_behavior_service.dart';
import 'notifications_settings.dart';

class NotificationService {
  static const int _driveUploadNotificationId = 9042;
  static const int saturationThreshold = 6;
  static final NotificationService _instance = NotificationService._internal();
  final CompletionBehaviorService _completionBehaviorService;
  final AdaptiveScheduler _adaptiveScheduler;

  factory NotificationService() => _instance;

  NotificationService._internal({
    CompletionBehaviorService? completionBehaviorService,
    AdaptiveScheduler? adaptiveScheduler,
  }) : _completionBehaviorService =
           completionBehaviorService ?? CompletionBehaviorService(),
       _adaptiveScheduler = adaptiveScheduler ?? AdaptiveScheduler() {
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
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
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

  Duration _reminderCadenceForTask(Tarea tarea, DateTime referenceNow) {
    final score = _focusScoreForTask(tarea, referenceNow);
    if (score >= 18) return const Duration(hours: 2);
    if (score >= 14) return const Duration(hours: 4);
    if (score >= 10) return const Duration(hours: 8);
    if (score >= 6) return const Duration(hours: 12);
    return const Duration(days: 1);
  }

  List<DateTime> _preDueReminderMomentsForTask(Tarea tarea) {
    final due = tarea.fechaVencimiento;
    final normalizedPriority = tarea.prioridad.toLowerCase();

    if (normalizedPriority == 'alta') {
      return [
        due.subtract(const Duration(days: 3)),
        due.subtract(const Duration(days: 1)),
        due.subtract(const Duration(hours: 3)),
      ];
    }

    if (normalizedPriority == 'media') {
      return [
        due.subtract(const Duration(days: 2)),
        due.subtract(const Duration(days: 1)),
      ];
    }

    return [due.subtract(const Duration(days: 1))];
  }

  List<DateTime> _applyAdaptiveWindows({
    required List<DateTime> reminderMoments,
    required DateTime due,
    required List<CompletionBehaviorEvent> events,
    required DateTime referenceNow,
  }) {
    return reminderMoments
        .map((scheduled) {
          return _adaptiveScheduler.alignReminder(
            scheduled: scheduled,
            due: due,
            events: events,
            referenceNow: referenceNow,
          );
        })
        .toList(growable: false);
  }

  List<DateTime> _preDueReminderMomentsForTaskWithHistory(
    Tarea tarea,
    List<CompletionBehaviorEvent> events, {
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final baseMoments = _preDueReminderMomentsForTask(tarea);
    final normalizedPriority = tarea.prioridad.toLowerCase();

    if (events.isEmpty) {
      return baseMoments;
    }

    List<int> baseLeadHours;
    if (normalizedPriority == 'alta') {
      baseLeadHours = const [72, 24, 3];
    } else if (normalizedPriority == 'media') {
      baseLeadHours = const [48, 24];
    } else {
      baseLeadHours = const [24];
    }

    final adjustedBaseMoments = baseLeadHours
        .map((leadHours) {
          final adjustedLead = _adaptiveScheduler.adjustedLeadHours(
            events: events,
            baseLeadHours: leadHours,
            referenceNow: now,
          );
          return tarea.fechaVencimiento.subtract(Duration(hours: adjustedLead));
        })
        .toList(growable: false);

    return _applyAdaptiveWindows(
      reminderMoments: adjustedBaseMoments,
      due: tarea.fechaVencimiento,
      events: events,
      referenceNow: now,
    );
  }

  // Public wrappers for testability
  String getImportanceText(Tarea tarea) => _importanceWithIcon(tarea);
  String getOverdueText(Tarea tarea) => _overdueTextFor(tarea);
  int getFocusScore(Tarea tarea, {DateTime? referenceNow}) =>
      _focusScoreForTask(tarea, referenceNow ?? DateTime.now());
  Duration getReminderCadence(Tarea tarea, {DateTime? referenceNow}) =>
      _reminderCadenceForTask(tarea, referenceNow ?? DateTime.now());
  List<DateTime> getPreDueReminderMoments(Tarea tarea) =>
      _preDueReminderMomentsForTask(tarea);
  List<DateTime> getPreDueReminderMomentsWithHistory(
    Tarea tarea,
    List<CompletionBehaviorEvent> events, {
    DateTime? referenceNow,
  }) => _preDueReminderMomentsForTaskWithHistory(
    tarea,
    events,
    referenceNow: referenceNow,
  );

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

  Future<void> _scheduleRecurringOverdueReminder(Tarea tarea) async {
    final id = _baseIdFromTask(tarea) + 7000;
    final color = _eisenhowerColorForTask(tarea);
    final body = _importanceWithIcon(tarea);
    final cadence = _reminderCadenceForTask(tarea, DateTime.now());

    await _scheduleNotification(
      id: id,
      title: 'Sigue pendiente: ${tarea.title}',
      body: body,
      color: color,
      taskId: tarea.id,
      schedule: NotificationInterval(
        interval: cadence,
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
    final behaviorEvents = await _completionBehaviorService.getRecentEvents(
      referenceNow: now,
    );
    final reminderMoments = _preDueReminderMomentsForTaskWithHistory(
      tarea,
      behaviorEvents,
      referenceNow: now,
    );
    final reminderIds = [1000, 2000, 3000];

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
          body: _importanceWithIcon(tarea),
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
          body: '${_overdueTextFor(tarea)} · ${_importanceWithIcon(tarea)}',
          color: _eisenhowerColorForTask(tarea),
          taskId: tarea.id,
        );
      }

      await _scheduleRecurringOverdueReminder(tarea);
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

  /// Returns the stable digest notification ID for a given calendar date.
  int digestIdForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.hashCode & 0x7fffffff;
  }

  /// Cancels pre-due reminder notifications (IDs +1000, +2000, +3000) for
  /// every task in [tasks].
  Future<void> cancelPreDueNotificationsForDay(List<Tarea> tasks) async {
    for (final tarea in tasks) {
      final base = _baseIdFromTask(tarea);
      for (final offset in const [1000, 2000, 3000]) {
        final id = base + offset;
        try {
          await AwesomeNotifications().cancelSchedule(id);
        } catch (_) {}
        try {
          await AwesomeNotifications().cancel(id);
        } catch (_) {}
      }
    }
  }

  /// Emits a digest notification for [day] summarising [tasks] (already
  /// ranked by caller).  Top-2 task titles are shown in the body.
  Future<void> notifyDigestForDay(DateTime day, List<Tarea> tasks) async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) return;

    final sorted = [...tasks]..sort(
      (a, b) =>
          _focusScoreForTask(b, day).compareTo(_focusScoreForTask(a, day)),
    );
    final top2 = sorted.take(2).map((t) => t.title).join(', ');
    final count = tasks.length;

    await _scheduleNotification(
      id: digestIdForDate(day),
      title: 'Hoy tenés $count tareas pendientes',
      body: 'Las más importantes: $top2',
      color: const Color(0xFF4E7BFF),
      taskId: 'digest_${day.year}_${day.month}_${day.day}',
      schedule: NotificationCalendar(
        hour: 8,
        minute: 0,
        second: 0,
        repeats: false,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelDriveUploadStatus() async {
    await AwesomeNotifications().cancel(_driveUploadNotificationId);
  }
}
