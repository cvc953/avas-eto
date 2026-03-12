import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDriveGrantedKey = 'drive_access_granted';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
);

const List<String> _driveScopes = [
  'https://www.googleapis.com/auth/drive.file',
];

enum GoogleLoginStatus {
  authenticatedWithDrive,
  authenticatedWithoutDrive,
  cancelled,
  failed,
}

enum DriveAccessRequestStatus { granted, cancelled, denied, failed }

class GoogleLoginResult {
  final GoogleLoginStatus status;
  final User? user;
  final String? message;
  final bool? driveGrantedOverride;

  const GoogleLoginResult({
    required this.status,
    this.user,
    this.message,
    this.driveGrantedOverride,
  });

  bool get isAuthenticated =>
      status == GoogleLoginStatus.authenticatedWithDrive ||
      status == GoogleLoginStatus.authenticatedWithoutDrive;

  bool get driveGranted =>
      driveGrantedOverride ?? status == GoogleLoginStatus.authenticatedWithDrive;
}

String? _cachedDriveAccessToken;
DateTime? _cachedDriveAccessTokenAt;

Future<void> _cacheDriveTokenFromAccount(GoogleSignInAccount? account) async {
  if (account == null) return;
  final token = (await account.authentication).accessToken;
  if (token == null || token.isEmpty) return;
  _cachedDriveAccessToken = token;
  _cachedDriveAccessTokenAt = DateTime.now();
  // Persiste que el usuario ya otorgó Drive para que sobreviva reinicios.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kDriveGrantedKey, true);
}

/// Persiste que el acceso a Drive fue revocado (sign-out o denegación).
Future<void> clearDriveGrantedPersisted() async {
  _cachedDriveAccessToken = null;
  _cachedDriveAccessTokenAt = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kDriveGrantedKey);
}

/// Devuelve `true` si el usuario concedió Drive en algún momento anterior
/// (valor persistido en disco; no requiere red).
Future<bool> hasDriveGrantedCached() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kDriveGrantedKey) ?? false;
}

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

    if (driveGranted) {
      // Refresh token after scope grant to ensure it carries Drive permissions.
      final tokenAccount = _googleSignIn.currentUser ?? googleUser;
      await _cacheDriveTokenFromAccount(tokenAccount);
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
  // 1. Token en memoria y vigente → OK inmediato.
  if (getCachedDriveAccessToken() != null) return true;

  // 2. Flag persistido en disco: el usuario ya autorizó anteriormente.
  //    Intentamos obtener un token silencioso para confirmar y refrescar.
  final persistedGranted = await hasDriveGrantedCached();

  final account =
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

  if (account == null) {
    // Sin sesión activa no podemos confirmar; confiamos en el flag.
    return persistedGranted;
  }

  try {
    final granted = await _googleSignIn.canAccessScopes(_driveScopes);
    if (granted) {
      await _cacheDriveTokenFromAccount(account);
      return true;
    }
    // canAccessScopes devolvió false, pero el usuario ya lo otorgó antes:
    // refrescamos el token silenciosamente y confiamos en el flag.
    if (persistedGranted) {
      await _cacheDriveTokenFromAccount(account);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Error verificando Drive scope: $e');
    if (persistedGranted) {
      await _cacheDriveTokenFromAccount(account);
      return true;
    }
    return getCachedDriveAccessToken() != null;
  }
}

Future<DriveAccessRequestStatus> requestDriveAccessInteractive() async {
  try {
    // Fuerza un nuevo consentimiento cuando sea posible, pero no aborta
    // si la desconexion falla por estado interno del plugin.
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('disconnect previo a Drive fallo (se continua): $e');
    }

    var account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();

    if (account == null) {
      return DriveAccessRequestStatus.cancelled;
    }

    var granted = false;
    try {
      granted = await _googleSignIn.canAccessScopes(_driveScopes);
    } catch (e) {
      debugPrint('canAccessScopes inicial fallo: $e');
    }

    if (!granted) {
      try {
        granted = await _googleSignIn.requestScopes(_driveScopes);
      } catch (e) {
        debugPrint('requestScopes fallo: $e');
      }
    }

    if (!granted) {
      // Verificacion final por si el consentimiento se completo pero el plugin
      // devolvio error/false transitorio.
      granted = await isDriveAccessGranted();
    }

    if (!granted) {
      await clearDriveGrantedPersisted();
      return DriveAccessRequestStatus.denied;
    }

    await _cacheDriveTokenFromAccount(_googleSignIn.currentUser ?? account);
    return DriveAccessRequestStatus.granted;
  } catch (e) {
    debugPrint('Error en requestDriveAccessInteractive: $e');
    if (await isDriveAccessGranted()) {
      return DriveAccessRequestStatus.granted;
    }
    return DriveAccessRequestStatus.failed;
  }
}

/// Garantiza el acceso a Drive durante el flujo de inicio de sesion.
///
/// Devuelve `granted` si ya estaba autorizado o si se autoriza
/// interactivamente en este intento.
Future<DriveAccessRequestStatus> ensureDriveAccessAfterLogin() async {
  return ensureDriveAccessAfterLoginWithOverrides();
}

Future<DriveAccessRequestStatus> ensureDriveAccessAfterLoginWithOverrides({
  Future<bool> Function()? isDriveGranted,
  Future<DriveAccessRequestStatus> Function()? requestDriveAccess,
}) async {
  final grantedCheck = isDriveGranted ?? isDriveAccessGranted;
  final requestAccess = requestDriveAccess ?? requestDriveAccessInteractive;

  if (await grantedCheck()) {
    return DriveAccessRequestStatus.granted;
  }
  return requestAccess();
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
    final persistedGranted = await hasDriveGrantedCached();
    try {
      final alreadyGranted = await _googleSignIn.canAccessScopes(_driveScopes);
      final granted =
          alreadyGranted ||
          persistedGranted ||
          (interactiveScopePrompt
              ? await _googleSignIn.requestScopes(_driveScopes)
              : false);
      if (!granted) {
        debugPrint('Permiso de Drive no otorgado por el usuario.');
        return null;
      }
    } catch (e) {
      debugPrint('Error solicitando Drive scope: $e');
      // Si hay flag persistido confiamos en él aunque el plugin falle.
      if (!persistedGranted) return null;
    }
  }

  final tokenAccount =
      requestDrive ? (_googleSignIn.currentUser ?? account) : account;
  final auth = await tokenAccount.authentication;
  final token = auth.accessToken;
  if (requestDrive && token != null && token.isNotEmpty) {
    await _cacheDriveTokenFromAccount(tokenAccount);
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
