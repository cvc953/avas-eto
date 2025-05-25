import 'package:ap/services/tarea_repository.dart';
import 'package:flutter/material.dart';
import 'tareas_inicio.dart';

class Tareas extends StatelessWidget {
  final TareaRepository tareaRepository;
  const Tareas({super.key, required this.tareaRepository});

  @override
  Widget build(BuildContext context) {
    return const TareasInicio();
  }
}
