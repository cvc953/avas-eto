import 'package:flutter/material.dart';
import '../utils/attachment_utils.dart';

class Tarea {
  final String localId;
  final String? firestoreId;
  String get id => localId;
  final String title;
  final String descripcion;
  final String prioridad;
  final Color color;
  final bool completada;
  final DateTime fechaCreacion;
  final DateTime fechaVencimiento;
  final DateTime fechaInicio;
  final int duracionMinutos;
  final bool todoElDia;
  final List<Map<String, dynamic>> adjuntos;
  final DateTime fechaCompletada;
  final int vecesPospuesta;

  Tarea({
    String? id,
    String? localId,
    this.firestoreId,
    required this.title,
    this.descripcion = '',
    this.prioridad = 'Media',
    required this.color,
    this.completada = false,
    required this.fechaCreacion,
    required this.fechaVencimiento,
    DateTime? fechaInicio,
    int? duracionMinutos,
    this.todoElDia = false,
    List<Map<String, dynamic>>? adjuntos,
    required this.fechaCompletada,
    this.vecesPospuesta = 0,
  }) : localId = (localId ?? id ?? ''),
       fechaInicio =
           fechaInicio ??
           fechaVencimiento.subtract(Duration(minutes: duracionMinutos ?? 60)),
       duracionMinutos =
           duracionMinutos ??
           fechaVencimiento
               .difference(
                 fechaInicio ??
                     fechaVencimiento.subtract(const Duration(minutes: 60)),
               )
               .inMinutes,
       adjuntos = List.unmodifiable(normalizeAttachments(adjuntos ?? const []));

  // Actualiza copyWith
  Tarea copyWith({
    String? id,
    String? localId,
    String? firestoreId,
    String? title,
    String? descripcion,
    String? prioridad,
    Color? color,
    bool? completada,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
    DateTime? fechaInicio,
    int? duracionMinutos,
    bool? todoElDia,
    List<Map<String, dynamic>>? adjuntos,
    DateTime? fechaCompletada,
    int? vecesPospuesta,
  }) {
    return Tarea(
      localId: localId ?? id ?? this.localId,
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      descripcion: descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      color: color ?? this.color,
      completada: completada ?? this.completada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      todoElDia: todoElDia ?? this.todoElDia,
      adjuntos: adjuntos ?? this.adjuntos,
      fechaCompletada: fechaCompletada ?? this.fechaCompletada,
      vecesPospuesta: vecesPospuesta ?? this.vecesPospuesta,
    );
  }

  // Actualiza toMap
  Map<String, dynamic> toMap() {
    return {
      'id': localId,
      'localId': localId,
      'firestoreId': firestoreId,
      'title': title,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'color': color.toARGB32().toRadixString(16),
      'completada': completada,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'fechaInicio': fechaInicio.toIso8601String(),
      'duracionMinutos': duracionMinutos,
      'todoElDia': todoElDia,
      'adjuntos': normalizeAttachments(adjuntos),
      'fechaCompletada': fechaCompletada.toIso8601String(),
      'vecesPospuesta': vecesPospuesta,
    };
  }

  // Actualiza fromMap
  factory Tarea.fromMap(Map<String, dynamic> map) {
    final parsedLocalId = (map['localId'] ?? map['id'] ?? '').toString();
    final parsedFirestoreId =
        map['firestoreId'] != null && map['firestoreId'].toString().isNotEmpty
            ? map['firestoreId'].toString()
            : null;

    return Tarea(
      localId: parsedLocalId,
      firestoreId: parsedFirestoreId,
      title: map['title'],
      descripcion: map['descripcion'] ?? '',
      prioridad: map['prioridad'] ?? 'Media',
      color: Color(
        int.tryParse(map['color'] ?? '0xFF000000', radix: 16) ?? 0xFF000000,
      ),
      completada: map['completada'] ?? false,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaVencimiento: DateTime.parse(map['fechaVencimiento']),
      fechaInicio:
          map['fechaInicio'] != null
              ? DateTime.parse(map['fechaInicio'])
              : DateTime.parse(map['fechaVencimiento']).subtract(
                Duration(minutes: (map['duracionMinutos'] ?? 60) as int),
              ),
      duracionMinutos: map['duracionMinutos'] ?? 60,
      todoElDia: map['todoElDia'] ?? false,
      adjuntos: _parseAdjuntos(map['adjuntos']),
      fechaCompletada: DateTime.parse(map['fechaCompletada']),
      vecesPospuesta: map['vecesPospuesta'] ?? 0,
    );
  }

  static List<Map<String, dynamic>> _parseAdjuntos(dynamic rawAdjuntos) {
    if (rawAdjuntos is! List) return const [];

    final parsed = <Map<String, dynamic>>[];
    for (final item in rawAdjuntos) {
      if (item is Map) {
        parsed.add(Map<String, dynamic>.from(item));
      }
    }
    return normalizeAttachments(parsed);
  }
}
