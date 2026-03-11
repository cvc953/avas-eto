import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:avas_eto/utils/app_toast.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Restablecer Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Ingresa tu correo electrónico para recibir un enlace de restablecimiento",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: _emailController.text.trim(),
                  );
                  AppToast.success(
                    context,
                    'Correo de restablecimiento enviado. Revisa tu bandeja de entrada.',
                  );
                  Navigator.pop(context);
                } on FirebaseAuthException catch (e) {
                  AppToast.error(context, 'Error: ${e.message}');
                }
              },
              child: Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
  }
}
