import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../utils/attachment_utils.dart';

Tarea tareaFromFirestore(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return Tarea(
    localId: (data['localId'] ?? doc.id).toString(),
    firestoreId: doc.id,
    title: data['titulo'] ?? '',
    descripcion: data['descripcion'] ?? '',
    prioridad: data['prioridad'] ?? 'Media',
    color: Color(
      int.tryParse(data['color'] ?? '0xFFFF0000', radix: 16) ?? 0xFFFF0000,
    ),
    completada: data['completada'] ?? false,
    fechaCreacion: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    fechaInicio:
        (data['inicio'] as Timestamp?)?.toDate() ??
        ((data['vencimiento'] as Timestamp?)?.toDate() ?? DateTime.now())
            .subtract(
              Duration(
                minutes: (data['duracionMinutos'] as num?)?.toInt() ?? 60,
              ),
            ),
    fechaVencimiento:
        (data['vencimiento'] as Timestamp?)?.toDate() ?? DateTime.now(),
    duracionMinutos: (data['duracionMinutos'] as num?)?.toInt() ?? 60,
    todoElDia: data['todoElDia'] ?? false,
    adjuntos: _parseAdjuntos(data['adjuntos']),
    fechaCompletada:
        (data['completadaEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

List<Map<String, dynamic>> _parseAdjuntos(dynamic rawAdjuntos) {
  if (rawAdjuntos is! List) return const [];

  final parsed = <Map<String, dynamic>>[];
  for (final item in rawAdjuntos) {
    if (item is Map) {
      parsed.add(Map<String, dynamic>.from(item));
    }
  }
  return normalizeAttachments(parsed);
}
