import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:avas_eto/utils/app_toast.dart';
import '../screens/tareas_inicio.dart';

class Google extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onFinish;

  const Google({super.key, required this.onStart, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SignInButton(
            Buttons.GoogleDark,
            text: 'Inicia con Google',
            onPressed: () async {
              onStart();
              try {
                final result = await signInWithGoogle(requestDriveAccess: true);
                if (!context.mounted) return;

                if (result.isAuthenticated) {
                  if (result.driveGranted) {
                    AppToast.success(
                      context,
                      'Sesion iniciada. Drive esta conectado para tus adjuntos.',
                    );
                  } else {
                    AppToast.warning(
                      context,
                      'Sesion iniciada en modo parcial. Puedes reautorizar Drive en Mas opciones.',
                    );
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TareasInicio()),
                  );
                } else if (result.status == GoogleLoginStatus.cancelled) {
                  AppToast.info(context, 'Inicio de sesion cancelado.');
                } else {
                  AppToast.error(
                    context,
                    result.message ?? 'Error al iniciar sesion con Google.',
                  );
                }
              } finally {
                onFinish();
              }
            },
          ),
        ],
      ),
    );
  }
}
