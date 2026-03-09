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
    final cardColor = Theme.of(context).cardColor;
    final dividerColor = Theme.of(context).dividerColor;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Avas-eto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organiza tus tareas por prioridad y urgencia, con sincronizacion y recordatorios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: bodyColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Que hace la app',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bullet(
                        'Crea tareas con titulo, descripcion, fecha y hora.',
                      ),
                      _bullet(
                        'Muestra tus tareas en lista y en Matriz de Eisenhower.',
                      ),
                      _bullet(
                        'Permite marcar, editar y eliminar tareas facilmente.',
                      ),
                      _bullet(
                        'Guarda tareas en local y sincroniza cuando hay conexion.',
                      ),
                      _bullet(
                        'Envia recordatorios para no olvidar tareas importantes.',
                      ),
                    ],
                  ),
                  cardColor: cardColor,
                  dividerColor: dividerColor,
                  titleColor: titleColor,
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Politica de privacidad',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bullet(
                        'Datos que puedes registrar: tareas, fechas, estado de completado y preferencias de uso.',
                      ),
                      _bullet(
                        'Uso de datos: los datos se usan para mostrar, ordenar y recordarte tus tareas dentro de la app.',
                      ),
                      _bullet(
                        'Almacenamiento: la informacion se guarda localmente en tu dispositivo y puede sincronizarse con tu cuenta cuando inicias sesion.',
                      ),
                      _bullet(
                        'Comparticion: la app no vende tus datos ni los comparte con terceros para publicidad.',
                      ),
                      _bullet(
                        'Control del usuario: puedes editar o eliminar tus tareas en cualquier momento.',
                      ),
                    ],
                  ),
                  cardColor: cardColor,
                  dividerColor: dividerColor,
                  titleColor: titleColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: bodyColor, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Divider(color: dividerColor),
                const SizedBox(height: 8),
                Text(
                  'Desarrollado por Cristian Villalobos Cuadrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: captionColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'GitHub de la app',
                      style: const TextStyle(
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
                ),
                const SizedBox(height: 8),
                Text(
                  'Tester: Luis Angel Gonzalez',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: captionColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 Licencia MIT.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: captionColor, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget content,
    required Color? cardColor,
    required Color? dividerColor,
    required Color? titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('- $text'),
    );
  }

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
