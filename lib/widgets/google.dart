import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:avas_eto/utils/app_toast.dart';
import '../screens/tareas_inicio.dart';

class Google extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final Future<GoogleLoginResult> Function({bool requestDriveAccess})
  signInWithGoogleFn;
  final Future<DriveAccessRequestStatus> Function() ensureDriveAccessFn;
  final Future<void> Function(BuildContext context)? onAuthenticated;
  final bool? showStatusToast;

  const Google({
    super.key,
    required this.onStart,
    required this.onFinish,
    this.signInWithGoogleFn = signInWithGoogle,
    this.ensureDriveAccessFn = ensureDriveAccessAfterLogin,
    this.onAuthenticated,
    this.showStatusToast,
  });

  bool _shouldShowToast() => showStatusToast ?? onAuthenticated == null;

  void _showToast(
    BuildContext context,
    void Function(BuildContext context, String message) show,
    String message,
  ) {
    if (!_shouldShowToast()) return;
    show(context, message);
  }

  Widget _buildButton(BuildContext context, double availableWidth) {
    final isCompact = availableWidth < 250;

    if (isCompact) {
      return IconButton(
        key: const Key('google-sign-in-button'),
        icon: const ImageIcon(AssetImage('assets/google_logo.png'), size: 24),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        onPressed: () => _handleLogin(context),
      );
    }

    return SignInButton(
      key: const Key('google-sign-in-button'),
      Buttons.GoogleDark,
      text: 'Inicia con Google',
      onPressed: () => _handleLogin(context),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    onStart();
    try {
      final result = await signInWithGoogleFn(requestDriveAccess: true);
      if (!context.mounted) return;

      if (result.isAuthenticated) {
        var driveGranted = result.driveGranted;
        if (!driveGranted) {
          final status = await ensureDriveAccessFn();
          driveGranted = status == DriveAccessRequestStatus.granted;
        }

        if (driveGranted) {
          _showToast(
            context,
            AppToast.success,
            'Sesion iniciada. Drive esta conectado para tus adjuntos.',
          );
        } else {
          _showToast(
            context,
            AppToast.warning,
            'Sesion iniciada en modo parcial. Puedes reautorizar Drive en Mas opciones.',
          );
        }
        if (onAuthenticated != null) {
          await onAuthenticated!(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TareasInicio()),
          );
        }
      } else if (result.status == GoogleLoginStatus.cancelled) {
        _showToast(context, AppToast.info, 'Inicio de sesion cancelado.');
      } else {
        _showToast(
          context,
          AppToast.error,
          result.message ?? 'Error al iniciar sesion con Google.',
        );
      }
    } finally {
      onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildButton(context, constraints.maxWidth);
        },
      ),
    );
  }
}
