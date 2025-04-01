import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class Google extends StatelessWidget {
  const Google({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SignInButton(
            Buttons.GoogleDark,
            text: 'Inicia sesión con Google',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
