import 'package:flutter/material.dart';

class VisSemana extends StatelessWidget {
  final List<Color> coloresDisponibles;
  const VisSemana({Key? key, required this.coloresDisponibles})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vista Semana')),
      body: Center(child: Text('Aquí irá la vista semanal de tareas.')),
    );
  }
}
