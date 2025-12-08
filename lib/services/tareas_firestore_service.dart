import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../utils/tarea_helpers.dart';

class TareasFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene stream de tareas del usuario actual
  Stream<QuerySnapshot> getTareasStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    return _firestore
        .collection('tareas')
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: false)
        .snapshots();
  }

  /// Guarda una nueva tarea en Firestore
  Future<String> guardarTarea(Tarea tarea, String fecha) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final docRef = await _firestore.collection('tareas').add({
      ...tareaToFirestoreMap(tarea, fecha),
      'creadoEn': FieldValue.serverTimestamp(),
      'userId': userId,
    });

    return docRef.id;
  }

  /// Actualiza una tarea existente
  Future<void> actualizarTarea(Tarea tarea, String fecha) async {
    if (tarea.id.isEmpty || tarea.id.startsWith('local_')) return;

    await _firestore
        .collection('tareas')
        .doc(tarea.id)
        .update(tareaToFirestoreMap(tarea, fecha));
  }

  /// Marca una tarea como completada
  Future<void> marcarCompletada(String tareaId, bool completada) async {
    if (tareaId.isEmpty || tareaId.startsWith('local_')) return;

    await _firestore.collection('tareas').doc(tareaId).update({
      'completada': completada,
    });
  }

  /// Actualiza la fecha/hora de una tarea
  Future<void> actualizarFecha(String tareaId, String nuevaFecha) async {
    if (tareaId.isEmpty || tareaId.startsWith('local_')) return;

    await _firestore.collection('tareas').doc(tareaId).update({
      'fecha': nuevaFecha,
      'hora': nuevaFecha.split('-').last,
    });
  }

  /// Elimina una tarea
  Future<void> eliminarTarea(String tareaId) async {
    if (tareaId.isEmpty || tareaId.startsWith('local_')) return;

    try {
      await _firestore.collection('tareas').doc(tareaId).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') {
        rethrow;
      }
    }
  }
}
