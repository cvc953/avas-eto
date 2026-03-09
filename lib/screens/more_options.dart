import 'package:avas_eto/screens/about_screen.dart';
import 'package:avas_eto/screens/login.dart';
import 'package:avas_eto/widgets/toggle_notifications.dart';
import 'package:avas_eto/widgets/bottom_navigation_bar.dart';
import 'package:avas_eto/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notifications_settings.dart';

class MoreOptions extends StatefulWidget {
  final List<Color> coloresDisponibles;

  const MoreOptions({super.key, this.coloresDisponibles = const []});

  @override
  State<MoreOptions> createState() => _MoreOptionsState();
}

class _MoreOptionsState extends State<MoreOptions> {
  final user = FirebaseAuth.instance.currentUser;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    enableNotifications();
  }

  void enableNotifications() async {
    // Lógica para habilitar o deshabilitar notificaciones
    notificationsEnabled = await NotificationSettings.isEnabled();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Center(
              child: Text(
                'Más opciones',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),

                if (user != null) ...[
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child:
                        user.photoURL == null
                            ? const Icon(Icons.account_circle, size: 80)
                            : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hola, ${user.email}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => _confirmSignOut(context),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.account_circle, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Inicia sesión para más opciones',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => Login()),
                      );
                    },
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],

                const SizedBox(height: 30),
                ListTile(
                  leading:
                      notificationsEnabled == true
                          ? Icon(Icons.notifications_on, color: Colors.white)
                          : Icon(Icons.notifications_off, color: Colors.white),
                  title: Text(
                    'Notificaciones',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final newValue = await showDialog<bool>(
                      context: context,
                      builder: (context) => ToggleNotifications(),
                    );
                    if (newValue != null) {
                      setState(() {
                        notificationsEnabled = newValue;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    ThemeService.instance.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Tema',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Switch(
                    value: ThemeService.instance.isDarkMode,
                    onChanged: (value) {
                      ThemeService.instance.setTheme(value);
                      setState(() {});
                    },
                    activeColor: Colors.blueAccent,
                  ),
                  subtitle: Text(
                    ThemeService.instance.isDarkMode ? 'Oscuro' : 'Claro',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'Acerca de',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.coloresDisponibles.isNotEmpty
              ? CustomBottomNavBar(
                  parentContext: context,
                  currentIndex: 2,
                  onSelect: (i) {
                    if (i == 0 || i == 1) {
                      Navigator.pop(context);
                    }
                  },
                  coloresDisponibles: widget.coloresDisponibles,
                )
              : null,
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Sí',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
