import 'package:flutter/material.dart';

class Tarea {
  final String id;
  final String title;
  final String descripcion;
  final String profesor;
  final int creditos;
  final int nrc;
  final String prioridad; // "alta", "media", "baja"
  final Color color;

  Tarea({
    String? id,
    required this.title,
    required this.descripcion,
    required this.profesor,
    required this.creditos,
    required this.nrc,
    required this.prioridad,
    required this.color,
  }) : id = id ?? _generateId();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'descripcion': descripcion,
      'profesor': profesor,
      'creditos': creditos,
      'nrc': nrc,
      'prioridad': prioridad,
      'color': color.value, // Guardamos el valor int del color
    };
  }

  // Método para crear Tarea desde Map (desde Firestore/Sembast)
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      profesor: map['profesor']?.toString() ?? '',
      creditos: map['creditos']?.toInt() ?? 0,
      nrc: map['nrc']?.toInt() ?? 0,
      prioridad: map['prioridad']?.toString() ?? 'media',
      color: Color(map['color'] ?? Colors.blue.value),
    );
  }

  // Método para clonar la tarea con cambios opcionales
  Tarea copyWith({
    String? id,
    String? title,
    String? descripcion,
    String? profesor,
    int? creditos,
    int? nrc,
    String? prioridad,
    Color? color,
  }) {
    return Tarea(
      id: id ?? this.id,
      title: title ?? this.title,
      descripcion: descripcion ?? this.descripcion,
      profesor: profesor ?? this.profesor,
      creditos: creditos ?? this.creditos,
      nrc: nrc ?? this.nrc,
      prioridad: prioridad ?? this.prioridad,
      color: color ?? this.color,
    );
  }

  // Método para comparar tareas (útil para pruebas y operaciones)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Tarea &&
        other.title == title &&
        other.descripcion == descripcion &&
        other.profesor == profesor &&
        other.creditos == creditos &&
        other.nrc == nrc &&
        other.prioridad == prioridad &&
        other.color.value == color.value;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        descripcion.hashCode ^
        profesor.hashCode ^
        creditos.hashCode ^
        nrc.hashCode ^
        prioridad.hashCode ^
        color.value.hashCode;
  }

  @override
  String toString() {
    return 'Tarea(title: $title, descripcion: $descripcion, profesor: $profesor, '
        'creditos: $creditos, nrc: $nrc, prioridad: $prioridad, color: $color)';
  }
}
