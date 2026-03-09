import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';

Tarea tareaFromFirestore(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return Tarea(
    id: doc.id,
    title: data['titulo'] ?? '',
    descripcion: data['descripcion'] ?? '',
    prioridad: data['prioridad'] ?? 'Media',
    color: Color(
      int.tryParse(data['color'] ?? '0xFFFF0000', radix: 16) ?? 0xFFFF0000,
    ),
    completada: data['completada'] ?? false,
    fechaCreacion: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    fechaVencimiento:
        (data['vencimiento'] as Timestamp?)?.toDate() ?? DateTime.now(),
    fechaCompletada:
        (data['completadaEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
