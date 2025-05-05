import 'package:ap/screens/tareas.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ap/screens/login.dart';

class Autenticacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // Usuario logueado
          return Tareas();
        } else {
          // Usuario no logueado
          //return Login();
          return Tareas();
        }
      },
    );
  }
}
