import 'package:flutter/material.dart';
import 'screens/tareas.dart'; // Importamos la pantalla de Tareas
import '../utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Tareas(), // Aquí se establece Tareas como la pantalla inicial
    );
  }
}
