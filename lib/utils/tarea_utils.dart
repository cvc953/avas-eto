import 'package:flutter/material.dart';

/// Utilitarios relacionados con visualización y prioridad de tareas
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

/// Formatea una fecha a DD/MM/YYYY
String formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year.toString().padLeft(4, '0')}';
}
