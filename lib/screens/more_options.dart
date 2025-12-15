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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
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
            // Aquí puedes agregar las opciones adicionales que desees
            //
            if (user != null) ...[
              SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    user!.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user!.photoURL == null
                        ? Icon(Icons.account_circle, size: 80)
                        : null,
              ),
              SizedBox(height: 20),
              Text('Hola, ${user!.email}'),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  setState(() {});
                },
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
            ] else ...[
              SizedBox(height: 20),
              const Icon(Icons.account_circle, size: 80),
              SizedBox(height: 20),
              Text('Inicia sesión para más opciones'),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                }, // Agrega la funcionalidad de inicio de sesión
                child: Text(
                  'Iniciar sesión',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            SizedBox(height: 30),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notificaciones '),
            ),
            ListTile(leading: Icon(Icons.info), title: Text('Acerca de')),
          ],
        ),
      ),
    );
  }
}
