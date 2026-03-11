import 'package:flutter_test/flutter_test.dart';
import 'package:avas_eto/services/notification_service.dart';
import 'package:avas_eto/models/tarea.dart';
import 'package:flutter/material.dart';

Future<Tarea> buildTarea(
  String id,
  DateTime fechaVencimiento, {
  String prioridad = 'Media',
}) async {
  return Tarea(
    id: id,
    title: 'Tarea $id',
    prioridad: prioridad,
    color: Colors.blue,
    fechaCreacion: DateTime.now(),
    fechaVencimiento: fechaVencimiento,
    fechaCompletada: DateTime.now(),
  );
}

void main() {
  test('colored quadrant contains font tag and hex color', () async {
    final ns = NotificationService();
    final tarea = await buildTarea(
      't1',
      DateTime.now().add(const Duration(days: 1)),
      prioridad: 'Alta',
    );
    final colored = ns.getColoredQuadrantText(tarea);
    expect(colored.contains('<font'), isTrue);
    expect(colored.contains('</font>'), isTrue);
    expect(colored.contains('#'), isTrue);
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
}
