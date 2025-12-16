import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

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
