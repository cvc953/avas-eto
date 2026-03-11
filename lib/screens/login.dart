import 'package:avas_eto/screens/tareas_inicio.dart';
import 'package:avas_eto/services/password_reset.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_toast.dart';
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
      appBar: AppBar(automaticallyImplyLeading: false),
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

                  _buildDriveExplanationCard(context),
                  const SizedBox(height: 14),

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
            ModalBarrier(
              dismissible: false,
              color: Theme.of(context).colorScheme.scrim.withAlpha(140),
            ),
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
      AppToast.warning(context, 'Por favor, completa todos los campos.');
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

      AppToast.error(context, mensaje);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildDriveExplanationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF152338) : const Color(0xFFEAF3FF);
    final border = isDark ? const Color(0xFF2F4F77) : const Color(0xFFA2C4EE);
    final title = isDark ? const Color(0xFFE8F2FF) : const Color(0xFF15314F);
    final body = isDark ? const Color(0xFFBDD1EC) : const Color(0xFF2A496C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: title),
              const SizedBox(width: 8),
              Text(
                'Sincronizacion segura con Google',
                style: TextStyle(
                  color: title,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usamos tu cuenta para sincronizar tareas en la nube (Firestore) y guardar adjuntos en tu Google Drive.\n\nSi no autorizas Drive, podras usar la app en modo parcial y reactivarlo luego desde Mas opciones.',
            style: TextStyle(color: body, height: 1.35),
          ),
        ],
      ),
    );
  }
}
