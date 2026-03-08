import 'package:flutter/material.dart';

/// Utilidad centralizada para generar claves únicas de tareas
/// Formato: YYYY-MM-DD-HH-MM
class TaskKeyGenerator {
  /// Genera una clave única basada en fecha y hora
  static String generateKey(DateTime date, TimeOfDay time) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}-'
        '${time.hour.toString().padLeft(2, '0')}-'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Genera una clave desde DateTime completo
  static String generateKeyFromDateTime(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.hour.toString().padLeft(2, '0')}-'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Parsea una clave para obtener DateTime
  static DateTime? parseKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 5) return null;

      return DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
        int.parse(parts[3]), // hour
        int.parse(parts[4]), // minute
      );
    } catch (e) {
      return null;
    }
  }

  /// Extrae solo la fecha de una clave (YYYY-MM-DD)
  static String getDateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}-${parts[2]}';
    }
    return key;
  }
}
