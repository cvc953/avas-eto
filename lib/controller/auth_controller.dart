import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avas_eto/services/local_storage_service.dart';

/// Encapsula operaciones de autenticación para mantener la UI libre de lógica.
class AuthController {
  final FirebaseAuth _auth;
  final LocalStorageService? _localStorage;

  AuthController({
    FirebaseAuth? firebaseAuth,
    LocalStorageService? localStorage,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _localStorage = localStorage;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Sign out and persist the last-signed-in uid on device so local tasks
  /// remain visible for that device owner. Optionally provide
  /// [currentUidOverride] for testing.
  Future<void> signOut({String? currentUidOverride}) async {
    try {
      final uid = currentUidOverride ?? _auth.currentUser?.uid;
      if (_localStorage != null) {
        await _localStorage!.setDeviceOwnerId(uid);
      }
    } catch (e) {
      // Non-fatal: persist best-effort
    }

    await _auth.signOut();
    await clearDriveGrantedPersisted();
  }
}
