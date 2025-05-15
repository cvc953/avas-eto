import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:ap/services/inicia_con_google.dart';

class Google extends StatelessWidget {
  const Google({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SignInButton(
            Buttons.GoogleDark,
            text: 'Inicia sesión con Google',
            onPressed: () async {
              final user = await signInWithGoogle();
              if (user != null) {
                print('Usuario autenticado: ${user.displayName}');
                // Puedes navegar a otra pantalla aquí
              } else {
                print('Error al iniciar sesión');
              }
            },
          ),
        ],
      ),
    );
  }
}

