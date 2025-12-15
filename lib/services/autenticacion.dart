import 'package:avas_eto/screens/tareas.dart';
import 'package:avas_eto/services/local_database.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/services/tarea_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Autenticacion extends StatelessWidget {
  const Autenticacion({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final localDb = LocalDatabase();
    final localStorage = LocalStorageService(localDb);
    final tareaRepository = TareaRepository(firestore, localStorage);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // Usuario logueado
          return Tareas(tareaRepository: tareaRepository);
        } else {
          // Usuario no logueado
          //return Login();
          return Tareas(tareaRepository: tareaRepository);
        }
      },
    );
  }
}
