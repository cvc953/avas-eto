import 'package:flutter_test/flutter_test.dart';
import 'package:avas_eto/services/notification_service.dart';
import 'package:avas_eto/models/tarea.dart';
import 'package:flutter/material.dart';

Future<Tarea> buildTarea(
  String id,
  DateTime fechaVencimiento, {
  String prioridad = 'Media',
  DateTime? fechaInicio,
  int duracionMinutos = 60,
  int vecesPospuesta = 0,
}) async {
  return Tarea(
    id: id,
    title: 'Tarea $id',
    prioridad: prioridad,
    color: Colors.blue,
    fechaCreacion: DateTime.now(),
    fechaVencimiento: fechaVencimiento,
    fechaInicio: fechaInicio,
    duracionMinutos: duracionMinutos,
    fechaCompletada: DateTime.now(),
    vecesPospuesta: vecesPospuesta,
  );
}

void main() {
  test('importance text contains colored icon and priority label', () async {
    final ns = NotificationService();
    final tarea = await buildTarea(
      't1',
      DateTime.now().add(const Duration(days: 1)),
      prioridad: 'Alta',
    );
    final importance = ns.getImportanceText(tarea);
    expect(importance.contains('<font'), isTrue);
    expect(importance.contains('●'), isTrue);
    expect(importance.contains('Alta'), isTrue);
  });

  test('overdue text produces human readable strings', () async {
    final ns = NotificationService();
    final tareaMinutes = await buildTarea(
      'm1',
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    final t1 = ns.getOverdueText(tareaMinutes);
    expect(t1.contains('Venció hace'), isTrue);

    final tareaHours = await buildTarea(
      'h1',
      DateTime.now().subtract(const Duration(hours: 3)),
    );
    final t2 = ns.getOverdueText(tareaHours);
    expect(t2.contains('hora') || t2.contains('horas'), isTrue);

    final tareaDays = await buildTarea(
      'd1',
      DateTime.now().subtract(const Duration(days: 2)),
    );
    final t3 = ns.getOverdueText(tareaDays);
    expect(t3.contains('día') || t3.contains('días'), isTrue);
  });

  test('high priority reminders follow 3d, 1d and 3h before due date', () async {
    final ns = NotificationService();
    final due = DateTime(2026, 3, 15, 12, 0);
    final tarea = await buildTarea('sched-high', due, prioridad: 'Alta');

    final reminders = ns.getPreDueReminderMoments(tarea);
    expect(reminders.length, 3);
    expect(reminders[0], due.subtract(const Duration(days: 3)));
    expect(reminders[1], due.subtract(const Duration(days: 1)));
    expect(reminders[2], due.subtract(const Duration(hours: 3)));
  });

  test('medium priority reminders follow 2d and 1d before due date', () async {
    final ns = NotificationService();
    final due = DateTime(2026, 3, 15, 12, 0);
    final tarea = await buildTarea('sched-medium', due, prioridad: 'Media');

    final reminders = ns.getPreDueReminderMoments(tarea);
    expect(reminders.length, 2);
    expect(reminders[0], due.subtract(const Duration(days: 2)));
    expect(reminders[1], due.subtract(const Duration(days: 1)));
  });

  test('low priority reminders follow 1d before due date', () async {
    final ns = NotificationService();
    final due = DateTime(2026, 3, 15, 12, 0);
    final tarea = await buildTarea('sched-low', due, prioridad: 'Baja');

    final reminders = ns.getPreDueReminderMoments(tarea);
    expect(reminders.length, 1);
    expect(reminders[0], due.subtract(const Duration(days: 1)));
  });

  test('focus score follows the provided formula', () async {
    final ns = NotificationService();
    final now = DateTime(2026, 3, 11, 8, 0);
    final tarea = await buildTarea(
      'score1',
      now.add(const Duration(hours: 2)),
      fechaInicio: now.add(const Duration(hours: 1)),
      duracionMinutos: 30,
      prioridad: 'Alta',
      vecesPospuesta: 2,
    );

    final score = ns.getFocusScore(tarea, referenceNow: now);
    expect(score, 18);
  });

  test('reminder cadence is derived from focus score', () async {
    final ns = NotificationService();
    final now = DateTime(2026, 3, 11, 8, 0);

    final urgentHighFocus = await buildTarea(
      'cad1',
      now.add(const Duration(hours: 2)),
      fechaInicio: now.add(const Duration(hours: 1)),
      duracionMinutos: 30,
      prioridad: 'Alta',
      vecesPospuesta: 2,
    );

    final lowFocus = await buildTarea(
      'cad2',
      now.add(const Duration(days: 10)),
      fechaInicio: now.add(const Duration(days: 8)),
      duracionMinutos: 90,
      prioridad: 'Baja',
      vecesPospuesta: 0,
    );

    expect(
      ns.getReminderCadence(urgentHighFocus, referenceNow: now),
      const Duration(hours: 2),
    );
    expect(
      ns.getReminderCadence(lowFocus, referenceNow: now),
      const Duration(days: 1),
    );
  });
}
