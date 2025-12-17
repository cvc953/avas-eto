import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Acerca de',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            //mainAxisAlignment: MainAxisAlignment.start,
            child: Column(
              children: [
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Avas-eto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Una aplicación de gestión de tareas desarrollada con Flutter que te permite organizar y administrar tus tareas de manera eficiente.',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '- ✅ Crear y gestionar tareas\n - 🎨 Asignar colores personalizados a cada tarea\n - 📋 Visualizar lista de tareas\n - ✏️ Editar tareas existentes\n - 🗑️ Eliminar tareas\n - 👤 Sistema de autenticación con inicio de sesión\n - 🔐 Integración con Google Sign-In\n - 📱 Interfaz de usuario moderna con tema oscuro',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '¡Gracias por usar Avas-eto!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Divider(color: Colors.white24),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        'Desarrollado por Cristian Villalobos Cuadrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'GitHub de la app',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () async {
                                  final url = Uri.parse(
                                    'http://github.com/cvc953/avas-eto',
                                  );
                                  _launchURL(url);
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Tester: Luis Angel Gonzalez',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    '© 2025 Licencia MIT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
