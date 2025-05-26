import 'package:flutter/material.dart';
import '../models/tarea.dart';

class TareaSearchDelegate extends SearchDelegate {
  final Map<String, List<Tarea>> tareas;

  TareaSearchDelegate({required this.tareas});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final resultados =
        tareas.entries
            .expand((entry) => entry.value)
            .where(
              (tarea) =>
                  tarea.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (resultados.isEmpty) {
      return const Center(
        child: Text(
          'No se ha encontrado ninguna tarea.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      children:
          resultados.map((tarea) {
            return ListTile(
              title: Text(tarea.title),
              leading: CircleAvatar(
                backgroundColor: tarea.color,
                child: const Icon(Icons.menu_book, color: Colors.white),
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final sugerencias =
        tareas.entries
            .expand((entry) => entry.value)
            .where(
              (tarea) =>
                  tarea.title.toLowerCase().startsWith(query.toLowerCase()),
            )
            .toList();

    if (sugerencias.isEmpty) {
      return const Center(
        child: Text(
          'No se ha encontrado ninguna tarea.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      children:
          sugerencias.map((tarea) {
            return ListTile(
              title: Text(tarea.title),
              leading: CircleAvatar(
                backgroundColor: tarea.color,
                child: Icon(Icons.menu_book, color: Colors.white),
              ),
            );
          }).toList(),
    );
  }
}
