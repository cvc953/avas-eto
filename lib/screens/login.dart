import 'package:avas_eto/screens/tareas_inicio.dart';
import 'package:avas_eto/services/password_reset.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/login_input.dart';
import '../widgets/google.dart';
import '../widgets/boton_inicio.dart';
import '../screens/registro.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          SafeArea(
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

                  GestureDetector(
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Botoninicio(onTap: () => inicio(context)),
                  const SizedBox(height: 20, width: 30),

                  Text('o', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),

                  Google(
                    onStart: () => setState(() => isLoading = true),
                    onFinish: () {
                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    },
                  ),

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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Registro()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ],
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

    setState(() {
      isLoading = true;
    });

    try {
      await auth.signInWithEmailAndPassword(email: email, password: pass);

      // Si todo sale bien, navega a la pantalla de tareas inicio
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TareasInicio()),
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
