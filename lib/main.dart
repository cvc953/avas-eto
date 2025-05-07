import 'package:flutter/material.dart';
import 'screens/tareas.dart'; // Importamos la pantalla de Tareas
import '../utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ap/services/autenticacion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      //home: const Tareas(),
      home: Autenticacion(),
    );
  }
}
