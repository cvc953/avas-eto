import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Encapsula operaciones de autenticación para mantener la UI libre de lógica.
class AuthController {
  final FirebaseAuth _auth;

  AuthController({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
    await clearDriveGrantedPersisted();
  }
}
