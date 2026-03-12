import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avas_eto/services/local_storage_service.dart';

/// Encapsula operaciones de autenticación para mantener la UI libre de lógica.
class AuthController {
  final FirebaseAuth? _auth;
  final LocalStorageService? _localStorage;
  final Future<void> Function() _clearDriveGrantedPersistedFn;

  AuthController({
    FirebaseAuth? firebaseAuth,
    LocalStorageService? localStorage,
    Future<void> Function()? clearDriveGrantedPersistedFn,
  }) : _auth = firebaseAuth ?? _resolveFirebaseAuth(),
       _localStorage = localStorage,
       _clearDriveGrantedPersistedFn =
           clearDriveGrantedPersistedFn ?? clearDriveGrantedPersisted;

  static FirebaseAuth? _resolveFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;

  Stream<User?> authStateChanges() =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Sign out and persist the last-signed-in uid on device so local tasks
  /// remain visible for that device owner. Optionally provide
  /// [currentUidOverride] for testing.
  Future<void> signOut({String? currentUidOverride}) async {
    try {
      final uid = currentUidOverride ?? _auth?.currentUser?.uid;
      if (_localStorage != null) {
        await _localStorage.setDeviceOwnerId(uid);
      }
    } catch (e) {
      // Non-fatal: persist best-effort
    }

    try {
      await _auth?.signOut();
    } catch (_) {
      // Non-fatal for tests and environments without Firebase wiring.
    }
    try {
      await _clearDriveGrantedPersistedFn();
    } catch (_) {
      // Non-fatal: local sign-out should still succeed in tests and fallback
      // environments where SharedPreferences is not wired.
    }
  }
}
