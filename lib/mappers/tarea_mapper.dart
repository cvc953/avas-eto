import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarea.dart';
import 'package:flutter/material.dart';

/// Mapper centralizado para conversiones entre Tarea y Firestore
class TareaMapper {
  /// Convierte una Tarea a Map para Firestore
  static Map<String, dynamic> toFirestoreMap(Tarea tarea, String clave) {
    return {
      'titulo': tarea.title,
      'descripcion': tarea.descripcion,
      'prioridad': tarea.prioridad,
      'color': tarea.color.toARGB32().toRadixString(16),
      'completada': tarea.completada,
      'fecha': clave,
      'hora': clave.split('-').last,
      'creadoEn': Timestamp.fromDate(tarea.fechaCreacion),
      'vencimiento': Timestamp.fromDate(tarea.fechaVencimiento),
      'completadaEn':
          tarea.completada
              ? Timestamp.fromDate(tarea.fechaCompletada)
              : Timestamp.fromDate(DateTime.now()),
      'vecesPospuesta': tarea.vecesPospuesta,
    };
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
      id: id,
      title: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      prioridad: data['prioridad'] ?? 'Media',
      color: Color(
        int.tryParse(data['color'] ?? 'FF000000', radix: 16) ?? 0xFF000000,
      ),
      completada: data['completada'] ?? false,
      fechaCreacion:
          (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaVencimiento:
          (data['vencimiento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCompletada:
          (data['completadaEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vecesPospuesta: data['vecesPospuesta'] ?? 0,
    );
  }

  /// Convierte lista de QueryDocumentSnapshots a lista de Tareas
  static List<Tarea> fromFirestoreQueryList(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) => fromFirestoreQueryDocument(doc)).toList();
  }
}
