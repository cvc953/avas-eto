import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

const List<String> _driveScopes = [
  'https://www.googleapis.com/auth/drive.file',
];

enum GoogleLoginStatus {
  authenticatedWithDrive,
  authenticatedWithoutDrive,
  cancelled,
  failed,
}

class GoogleLoginResult {
  final GoogleLoginStatus status;
  final User? user;
  final String? message;

  const GoogleLoginResult({required this.status, this.user, this.message});

  bool get isAuthenticated =>
      status == GoogleLoginStatus.authenticatedWithDrive ||
      status == GoogleLoginStatus.authenticatedWithoutDrive;

  bool get driveGranted => status == GoogleLoginStatus.authenticatedWithDrive;
}

String? _cachedDriveAccessToken;
DateTime? _cachedDriveAccessTokenAt;

Future<GoogleLoginResult> signInWithGoogle({
  bool requestDriveAccess = true,
}) async {
  try {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return const GoogleLoginResult(status: GoogleLoginStatus.cancelled);
    }

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) throw Exception("ID Token es nulo");

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    var driveGranted = true;
    if (requestDriveAccess) {
      driveGranted = await _requestDriveScope();
    }

    final token = googleAuth.accessToken;
    if (driveGranted && token != null && token.isNotEmpty) {
      _cachedDriveAccessToken = token;
      _cachedDriveAccessTokenAt = DateTime.now();
    }

    return GoogleLoginResult(
      status:
          driveGranted
              ? GoogleLoginStatus.authenticatedWithDrive
              : GoogleLoginStatus.authenticatedWithoutDrive,
      user: userCredential.user,
    );
  } catch (e, s) {
    debugPrint('Error al iniciar sesión con Google: $e');
    debugPrintStack(stackTrace: s);
    return const GoogleLoginResult(
      status: GoogleLoginStatus.failed,
      message: 'No se pudo iniciar sesion con Google.',
    );
  }
}

Future<bool> _requestDriveScope() async {
  try {
    final alreadyGranted = await _googleSignIn.canAccessScopes(_driveScopes);
    if (alreadyGranted) return true;
    return await _googleSignIn.requestScopes(_driveScopes);
  } catch (e) {
    debugPrint('Error solicitando Drive scope: $e');
    return false;
  }
}

Future<bool> isDriveAccessGranted() async {
  final account =
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  if (account == null) return false;
  try {
    return await _googleSignIn.canAccessScopes(_driveScopes);
  } catch (e) {
    debugPrint('Error verificando Drive scope: $e');
    return false;
  }
}

Future<bool> requestDriveAccessInteractive() async {
  final account =
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  if (account == null) return false;
  final granted = await _requestDriveScope();
  if (!granted) return false;
  final token = (await account.authentication).accessToken;
  if (token != null && token.isNotEmpty) {
    _cachedDriveAccessToken = token;
    _cachedDriveAccessTokenAt = DateTime.now();
  }
  return true;
}

Future<String?> getGoogleAccessToken({
  bool requestDrive = false,
  bool interactiveScopePrompt = true,
}) async {
  final silentAccount =
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  final account =
      silentAccount ??
      ((requestDrive && interactiveScopePrompt)
          ? await _googleSignIn.signIn()
          : null);

  if (account == null) {
    return requestDrive ? getCachedDriveAccessToken() : null;
  }

  // Solicita scope de Drive solo si el usuario intenta adjuntar
  if (requestDrive) {
    try {
      final alreadyGranted = await _googleSignIn.canAccessScopes(_driveScopes);
      final granted =
          alreadyGranted ||
          (interactiveScopePrompt
              ? await _googleSignIn.requestScopes(_driveScopes)
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
  final token = auth.accessToken;
  if (requestDrive && token != null && token.isNotEmpty) {
    _cachedDriveAccessToken = token;
    _cachedDriveAccessTokenAt = DateTime.now();
  }
  return token;
}

String? getCachedDriveAccessToken({
  Duration maxAge = const Duration(minutes: 50),
}) {
  final token = _cachedDriveAccessToken;
  final issuedAt = _cachedDriveAccessTokenAt;
  if (token == null || issuedAt == null) return null;
  if (DateTime.now().difference(issuedAt) > maxAge) {
    _cachedDriveAccessToken = null;
    _cachedDriveAccessTokenAt = null;
    return null;
  }
  return token;
}
