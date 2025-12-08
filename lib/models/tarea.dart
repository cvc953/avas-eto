import 'package:flutter/material.dart';

class Tarea {
  final String id;
  final String title;
  final String materia;
  final String descripcion;
  final String profesor;
  final int creditos;
  final int nrc;
  final String prioridad;
  final Color color;
  final bool completada;
  final DateTime fechaCreacion;

  Tarea({
    required this.id,
    required this.title,
    this.materia = '',
    this.descripcion = '',
    this.profesor = '',
    this.creditos = 0,
    this.nrc = 0,
    this.prioridad = 'Media',
    required this.color,
    this.completada = false,
    required this.fechaCreacion,
  });

  // Actualiza copyWith
  Tarea copyWith({
    String? id,
    String? title,
    String? materia,
    String? descripcion,
    String? profesor,
    int? creditos,
    int? nrc,
    String? prioridad,
    Color? color,
    bool? completada,
    DateTime? fechaCreacion,
  }) {
    return Tarea(
      id: id ?? this.id,
      title: title ?? this.title,
      materia: materia ?? this.materia,
      descripcion: descripcion ?? this.descripcion,
      profesor: profesor ?? this.profesor,
      creditos: creditos ?? this.creditos,
      nrc: nrc ?? this.nrc,
      prioridad: prioridad ?? this.prioridad,
      color: color ?? this.color,
      completada: completada ?? this.completada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Actualiza toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'descripcion': descripcion,
      'profesor': profesor,
      'creditos': creditos,
      'nrc': nrc,
      'prioridad': prioridad,
      'color': color.toARGB32().toRadixString(16),
      'completada': completada,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Actualiza fromMap
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      title: map['title'],
      descripcion: map['descripcion'] ?? '',
      profesor: map['profesor'] ?? '',
      creditos: map['creditos'] ?? 0,
      nrc: map['nrc'] ?? 0,
      prioridad: map['prioridad'] ?? 'Media',
      color: Color(int.parse(map['color'] ?? '0xFF000000', radix: 16)),
      completada: map['completada'] ?? false,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}
