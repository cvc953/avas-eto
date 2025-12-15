import 'package:flutter/material.dart';

class Tarea {
  final String id;
  final String title;
  final String descripcion;
  final String prioridad;
  final Color color;
  final bool completada;
  final DateTime fechaCreacion;
  final DateTime fechaVencimiento;
  final DateTime fechaCompletada;

  Tarea({
    required this.id,
    required this.title,
    this.descripcion = '',
    this.prioridad = 'Media',
    required this.color,
    this.completada = false,
    required this.fechaCreacion,
    required this.fechaVencimiento,
    required this.fechaCompletada,
  });

  // Actualiza copyWith
  Tarea copyWith({
    String? id,
    String? title,
    String? descripcion,
    String? prioridad,
    Color? color,
    bool? completada,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
    DateTime? fechaCompletada,
  }) {
    return Tarea(
      id: id ?? this.id,
      title: title ?? this.title,
      descripcion: descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      color: color ?? this.color,
      completada: completada ?? this.completada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaCompletada: fechaCompletada ?? this.fechaCompletada,
    );
  }

  // Actualiza toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'color': color.toARGB32().toRadixString(16),
      'completada': completada,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'fechaCompletada': fechaCompletada.toIso8601String(),
    };
  }

  // Actualiza fromMap
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      title: map['title'],
      descripcion: map['descripcion'] ?? '',
      prioridad: map['prioridad'] ?? 'Media',
      color: Color(
        int.tryParse(map['color'] ?? '0xFF000000', radix: 16) ?? 0xFF000000,
      ),
      completada: map['completada'] ?? false,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaVencimiento: DateTime.parse(map['fechaVencimiento']),
      fechaCompletada: DateTime.parse(map['fechaCompletada']),
    );
  }
}
