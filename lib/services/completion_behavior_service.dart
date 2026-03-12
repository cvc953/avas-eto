import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../models/completion_behavior_event.dart';
import '../models/tarea.dart';
import 'local_database.dart';

class CompletionBehaviorService {
  static const Duration retention = Duration(days: 30);
  static const String _ownerUserIdKey = '_ownerUserId';

  final LocalDatabase _localDatabase;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth _auth;
  final StoreRef<String, Map<String, dynamic>> _store =
      StoreRef<String, Map<String, dynamic>>('completion_behavior');

  CompletionBehaviorService({
    LocalDatabase? localDatabase,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _localDatabase = localDatabase ?? LocalDatabase(),
       _firestore = firestore,
       _auth = auth ?? FirebaseAuth.instance;

  Future<void> recordCompletion(Tarea tarea, {DateTime? completedAt}) async {
    final completionTime = completedAt ?? DateTime.now();
    final event = CompletionBehaviorEvent.fromTask(
      taskId: tarea.id,
      completedAt: completionTime,
      dueAt: tarea.fechaVencimiento,
    );

    await _purgeExpiredLocal();
    await _saveLocalEvent(event);
    await _saveRemoteEvent(event);
  }

  Future<List<CompletionBehaviorEvent>> getRecentEvents({
    DateTime? referenceNow,
  }) async {
    final now = referenceNow ?? DateTime.now();
    await _purgeExpiredLocal(referenceNow: now);

    final localEvents = await _readLocalEvents(referenceNow: now);
    final remoteEvents = await _readRemoteEvents(referenceNow: now);
    final merged = <String, CompletionBehaviorEvent>{
      for (final event in localEvents) event.id: event,
      for (final event in remoteEvents) event.id: event,
    };

    final result =
        merged.values.toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return result;
  }

  Future<void> _saveLocalEvent(CompletionBehaviorEvent event) async {
    try {
      final database = await _localDatabase.db;
      final ownerId = _auth.currentUser?.uid;
      final map = event.toMap();
      if (ownerId != null && ownerId.isNotEmpty) {
        map[_ownerUserIdKey] = ownerId;
      }
      await _store.record(event.id).put(database, map);
    } catch (e) {
      debugPrint('Error guardando evento de comportamiento local: $e');
    }
  }

  Future<void> _saveRemoteEvent(CompletionBehaviorEvent event) async {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('completion_behavior')
          .doc(event.id)
          .set({
            ...event.toMap(),
            'completedAt': Timestamp.fromDate(event.completedAt),
            'dueAt': Timestamp.fromDate(event.dueAt),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando evento de comportamiento remoto: $e');
    }
  }

  Future<List<CompletionBehaviorEvent>> _readLocalEvents({
    required DateTime referenceNow,
  }) async {
    try {
      final database = await _localDatabase.db;
      final ownerId = _auth.currentUser?.uid;
      final records = await _store.find(database);

      return records
          .where((record) {
            final recordOwner = record.value[_ownerUserIdKey] as String?;
            if (ownerId == null || ownerId.isEmpty) {
              return recordOwner == null;
            }
            return recordOwner == ownerId;
          })
          .map((record) => CompletionBehaviorEvent.fromMap(record.value))
          .where((event) => !_isExpired(event, referenceNow))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error leyendo eventos de comportamiento local: $e');
      return const [];
    }
  }

  Future<List<CompletionBehaviorEvent>> _readRemoteEvents({
    required DateTime referenceNow,
  }) async {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    final user = _auth.currentUser;
    if (user == null) return const [];

    try {
      final cutoff = referenceNow.subtract(retention);
      final snapshot =
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('completion_behavior')
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
              )
              .get();

      return snapshot.docs
          .map((doc) {
            final map = Map<String, dynamic>.from(doc.data());
            map['completedAt'] =
                (map['completedAt'] as Timestamp).toDate().toIso8601String();
            map['dueAt'] =
                (map['dueAt'] as Timestamp).toDate().toIso8601String();
            return CompletionBehaviorEvent.fromMap(map);
          })
          .where((event) => !_isExpired(event, referenceNow))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error leyendo eventos de comportamiento remoto: $e');
      return const [];
    }
  }

  Future<void> _purgeExpiredLocal({DateTime? referenceNow}) async {
    try {
      final now = referenceNow ?? DateTime.now();
      final database = await _localDatabase.db;
      final records = await _store.find(database);
      for (final record in records) {
        final event = CompletionBehaviorEvent.fromMap(record.value);
        if (_isExpired(event, now)) {
          await _store.record(record.key).delete(database);
        }
      }
    } catch (e) {
      debugPrint('Error purgando eventos de comportamiento local: $e');
    }
  }

  bool _isExpired(CompletionBehaviorEvent event, DateTime referenceNow) {
    return referenceNow.difference(event.completedAt) > retention;
  }
}
