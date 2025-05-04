import 'package:ap/screens/paginaprincipal.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/login_input.dart';
import '../widgets/google.dart';
import '../widgets/boton_inicio.dart';
import '../screens/registro.dart';
import '../main.dart';

class Login extends StatelessWidget {
  Login({super.key}); // Quitado el const porque tiene campos no constantes

  final username = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.email_rounded, size: 80),
              const SizedBox(height: 10),
              //Text('bienvenido', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              LoginInput(
                controller: username,
                hintText: 'Usuario',
                obscureText: false,
              ),

              LoginInput(
                controller: password,
                hintText: 'Contraseña',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              Botoninicio(onTap: () => inicio(context)),
              const SizedBox(height: 20),

              Text('o', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),

              const Google(),

              const SizedBox(height: 60),

              Text(
                '¿No tienes cuenta?',
                style: TextStyle(color: Colors.grey[600]),
              ),
              GestureDetector(
                child: const Text(
                  'Registrate',
                  style: TextStyle(color: Colors.blue),
                ),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => Registro()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void inicio(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final email = username.text.trim();
    final pass = password.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(email: email, password: pass);

      // Si todo sale bien, navega al home (reemplaza esto con tu pantalla principal)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Paginaprincipal(),
        ), // Cambia esto si tienes otra pantalla principal
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';

      if (e.code == 'user-not-found') {
        mensaje = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }
}
