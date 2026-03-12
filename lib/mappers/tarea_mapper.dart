import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarea.dart';
import 'package:flutter/material.dart';
import '../utils/attachment_utils.dart';

/// Mapper centralizado para conversiones entre Tarea y Firestore
class TareaMapper {
  /// Convierte una Tarea a Map para Firestore.
  /// Los adjuntos se guardan sin la ruta local del dispositivo (`path`),
  /// ya que esa ruta no tiene valor fuera del dispositivo donde se creó.
  static Map<String, dynamic> toFirestoreMap(Tarea tarea, String clave) {
    return {
      'localId': tarea.localId,
      'titulo': tarea.title,
      'descripcion': tarea.descripcion,
      'prioridad': tarea.prioridad,
      'color': tarea.color.toARGB32().toRadixString(16),
      'completada': tarea.completada,
      'fecha': clave,
      'hora': clave.split('-').last,
      'creadoEn': Timestamp.fromDate(tarea.fechaCreacion),
      'inicio': Timestamp.fromDate(tarea.fechaInicio),
      'vencimiento': Timestamp.fromDate(tarea.fechaVencimiento),
      'duracionMinutos': tarea.duracionMinutos,
      'todoElDia': tarea.todoElDia,
      'adjuntos': toFirestoreAdjuntos(tarea.adjuntos),
      'completadaEn':
          tarea.completada
              ? Timestamp.fromDate(tarea.fechaCompletada)
            : null,
      'vecesPospuesta': tarea.vecesPospuesta,
    };
  }

  /// Convierte la lista de adjuntos a formato Firestore (sin `path` local).
  static List<Map<String, dynamic>> toFirestoreAdjuntos(
    List<Map<String, dynamic>> adjuntos,
  ) {
    return adjuntos
        .map((a) {
          final m = normalizeAttachment(a);
          m.remove('path');
          return m;
        })
        .toList(growable: false);
  }

  /// Convierte un DocumentSnapshot de Firestore a Tarea
  static Tarea fromFirestoreDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _fromFirestoreData(doc.id, data);
  }

  /// Convierte un QueryDocumentSnapshot de Firestore a Tarea
  static Tarea fromFirestoreQueryDocument(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _fromFirestoreData(doc.id, data);
  }

  /// Lógica interna de conversión desde data de Firestore
  static Tarea _fromFirestoreData(String id, Map<String, dynamic> data) {
    return Tarea(
      localId: (data['localId'] ?? id).toString(),
      firestoreId: id,
      title: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      prioridad: data['prioridad'] ?? 'Media',
      color: Color(
        int.tryParse(data['color'] ?? 'FF000000', radix: 16) ?? 0xFF000000,
      ),
      completada: data['completada'] ?? false,
      fechaCreacion:
          (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
          (data['completadaEn'] as Timestamp?)?.toDate() ?? DateTime(0),
      vecesPospuesta: data['vecesPospuesta'] ?? 0,
    );
  }

  /// Convierte lista de QueryDocumentSnapshots a lista de Tareas
  static List<Tarea> fromFirestoreQueryList(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) => fromFirestoreQueryDocument(doc)).toList();
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
