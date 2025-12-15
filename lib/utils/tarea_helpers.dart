import 'package:avas_eto/models/tarea.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Helper para convertir Tarea a mapa de Firestore
Map<String, dynamic> tareaToFirestoreMap(Tarea tarea, String fecha) {
  return {
    'titulo': tarea.title,
    'descripcion': tarea.descripcion,
    'prioridad': tarea.prioridad,
    'color': tarea.color.toARGB32().toRadixString(16),
    'completada': tarea.completada,
    'fecha': fecha,
    'hora': fecha.split('-').last,
    'creadoEn': Timestamp.fromDate(tarea.fechaCreacion),
    'vencimiento': Timestamp.fromDate(tarea.fechaVencimiento),
    'completadaEn':
        tarea.completada
            ? Timestamp.fromDate(tarea.fechaCompletada)
            : Timestamp.fromDate(DateTime.now()),
  };
}

/// Helper para convertir documento de Firestore a Tarea
Tarea documentToTarea(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Tarea(
    id: doc.id,
    title: data['titulo'] ?? '',
    descripcion: data['descripcion'] ?? '',
    prioridad: data['prioridad'] ?? 'Media',
    color: Color(
      int.tryParse(data['color'] ?? '0xFF000000', radix: 16) ?? 0xFF000000,
    ),
    completada: data['completada'] ?? false,
    fechaCreacion: (data['creadoEn'] as Timestamp).toDate(),
    fechaVencimiento: DateTime.parse(data['fecha'] as String),
    fechaCompletada:
        data['completada']
            ? (data['completadaEn'] as Timestamp).toDate()
            : DateTime.now(),
  );
}

/// Helper para extraer fecha de una clave de formato 'YYYY-MM-DD-HH'
DateTime dateFromTaskKey(String taskKey) {
  final partes = taskKey.split('-');
  return DateTime(
    int.parse(partes[0]),
    int.parse(partes[1]),
    int.parse(partes[2]),
  );
}

/// Helper para obtener la hora de una clave de formato 'YYYY-MM-DD-HH'
String hourFromTaskKey(String taskKey) {
  final partes = taskKey.split('-');
  return partes.last.padLeft(2, '0');
}

/// Helper para generar clave de tarea
String getTaskKey(DateTime day, int hour, [int minute = 0]) {
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}-${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}';
}

/// Helper para obtener color de prioridad
Color getPrioridadColor(String prioridad) {
  switch (prioridad) {
    case 'Alta':
      return Colors.red;
    case 'Media':
      return Colors.orange;
    case 'Baja':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// Helper para formatear fecha en formato DD/MM/YYYY
String formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year.toString().padLeft(4, '0')}';
}
