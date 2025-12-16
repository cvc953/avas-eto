import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:avas_eto/services/inicia_con_google.dart';
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
                final user = await signInWithGoogle();
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TareasInicio()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al iniciar sesión con Google'),
                    ),
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
