import 'package:flutter/material.dart';

class Tarea {
  final String title;
  final String descripcion;
  final String profesor;
  final int creditos;
  final int nrc;
  final String prioridad; // "alta", "media", "baja"
  final Color color;

  Tarea({
    required this.title,
    required this.descripcion,
    required this.profesor,
    required this.creditos,
    required this.nrc,
    required this.prioridad,
    required this.color,
  });
}
