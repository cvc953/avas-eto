import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'], // Drive solicitado solo cuando sea necesario
);

Future<User?> signInWithGoogle() async {
  try {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) throw Exception("ID Token es nulo");

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return userCredential.user;
  } catch (e, s) {
    debugPrint('Error al iniciar sesión con Google: $e');
    debugPrintStack(stackTrace: s);
    print("Error al iniciar sesión con Google: $e");
    return null;
  }
}

Future<String?> getGoogleAccessToken({
  bool requestDrive = false,
  bool interactiveScopePrompt = true,
}) async {
  final account =
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

  if (account == null) return null;

  // Solicita scope de Drive solo si el usuario intenta adjuntar
  if (requestDrive) {
    try {
      const driveScopes = ['https://www.googleapis.com/auth/drive.file'];
      final alreadyGranted = await _googleSignIn.canAccessScopes(driveScopes);
      final granted =
          alreadyGranted ||
          (interactiveScopePrompt
              ? await _googleSignIn.requestScopes(driveScopes)
              : false);
      if (!granted) {
        debugPrint('Permiso de Drive no otorgado por el usuario.');
        return null;
      }
    } catch (e) {
      debugPrint('Error solicitando Drive scope: $e');
      return null; // Usuario rechazó el permiso
    }
  }

  final auth = await account.authentication;
  return auth.accessToken;
}
