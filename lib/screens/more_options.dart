import 'package:avas_eto/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoreOptions extends StatefulWidget {
  const MoreOptions({super.key});

  @override
  State<MoreOptions> createState() => _MoreOptionsState();
}

class _MoreOptionsState extends State<MoreOptions> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
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
                const ListTile(
                  leading: Icon(Icons.notifications, color: Colors.white),
                  title: Text(
                    'Notificaciones',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: null,
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
