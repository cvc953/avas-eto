import 'package:avas_eto/screens/tareas_inicio.dart';
import 'package:avas_eto/widgets/login_input.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Registro extends StatelessWidget {
  Registro({super.key});

  final email = TextEditingController();
  final password = TextEditingController();
  final password2 = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register(BuildContext context) async {
    if (password.text != password2.text) {
      _showDialog(context, 'Las contraseñas no coinciden');
      return;
    }

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      if (userCredential.user != null) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => TareasInicio()));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error desconocido';

      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está en uso.';
      } else if (e.code == 'invalid-email') {
        message = 'Correo inválido.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil.';
      }

      _showDialog(context, message);
    }
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Registro fallido'),
            content: Text(message),
            actions: [
              TextButton(
                child: Text('Aceptar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Registro")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Icon(Icons.email_rounded, size: 80),
              SizedBox(height: 10),
              LoginInput(
                controller: email,
                hintText: 'Email',
                obscureText: false,
              ),
              LoginInput(
                controller: password,
                hintText: 'Contraseña',
                obscureText: true,
              ),
              LoginInput(
                controller: password2,
                hintText: 'Repetir contraseña',
                obscureText: true,
              ),
              SizedBox(height: 20),
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin: EdgeInsets.symmetric(horizontal: 70),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Regístrate',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onTap: () => _register(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
