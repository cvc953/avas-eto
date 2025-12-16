import 'package:avas_eto/screens/login.dart';
import 'package:avas_eto/widgets/toggle_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notifications_settings.dart';

class MoreOptions extends StatefulWidget {
  const MoreOptions({super.key});

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
                const ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'Acerca de',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: null,
                ),
              ],
            ),
          ),
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
