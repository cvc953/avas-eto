import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class AboutScreen extends StatelessWidget {
  final Future<void> Function(dynamic tarea)? onAddTask;
  final Future<void> Function(dynamic tarea, bool)? onToggle;
  const AboutScreen({super.key, this.onAddTask, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.titleLarge?.color;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final captionColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Acerca de',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Avas-eto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Una aplicacion de gestion de tareas desarrollada con Flutter que te permite organizar y administrar tus tareas de manera eficiente.',
                  textAlign: TextAlign.left,
                  style: TextStyle(color: bodyColor, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: bodyColor, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '¡Gracias por usar Avas-eto!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(color: Theme.of(context).dividerColor),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Desarrollado por Cristian Villalobos Cuadrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: captionColor, fontSize: 12),
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
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Tester: Luis Angel Gonzalez',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: captionColor, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  '© 2025 Licencia MIT.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: captionColor, fontSize: 12),
                ),
              ),
              const SizedBox(height: 30),
            ],
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
