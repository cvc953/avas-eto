import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage_service.dart';
import '../models/tarea.dart';

class TareaRepository {
  final FirebaseFirestore? _firestore;
  final LocalStorageService _localStorage;

  TareaRepository(this._firestore, this._localStorage);

  Future<void> saveTarea(Tarea tarea) async {
    // Primero guardar localmente
    await _localStorage.saveTarea(tarea);

    // Luego intentar Firestore si está disponible
    if (_firestore != null) {
      try {
        await _firestore!.collection('tareas').doc(tarea.id).set(tarea.toMap());
      } catch (e) {
        print('Error al sincronizar con Firestore: $e');
        throw Exception('No se pudo guardar en Firestore');
      }
    }
  }

  Future<List<Tarea>> getTareas() async {
    // Si Firestore no está disponible, devolver solo locales
    if (_firestore == null) {
      return await _localStorage.getTareas();
    }

    try {
      final snapshot = await _firestore!.collection('tareas').get();
      final tareas = <Tarea>[];

      // Procesar documentos de Firestore
      for (var doc in snapshot.docs) {
        try {
          final tareaData = doc.data();
          tareaData['id'] = doc.id; // Asegurar que el ID esté incluido

          final tarea = Tarea.fromMap(tareaData);
          await _localStorage.saveTarea(tarea);
          tareas.add(tarea);
        } catch (e) {
          print('Error procesando documento ${doc.id}: $e');
        }
      }

      return tareas;
    } catch (e) {
      print('Error obteniendo tareas de Firestore: $e');
      return await _localStorage.getTareas();
    }
  }

  Future<void> deleteTarea(String id) async {
    // Eliminar localmente
    await _localStorage.deleteTarea(id);

    // Eliminar de Firestore si está disponible
    if (_firestore != null) {
      try {
        await _firestore!.collection('tareas').doc(id).delete();
      } catch (e) {
        print('Error eliminando tarea de Firestore: $e');
        throw Exception('No se pudo eliminar de Firestore');
      }
    }
  }
}
