import 'package:flutter/material.dart';
import '../models/tarea.dart';

Future<Tarea?> mostrarDialogoEditarTarea({
  required BuildContext context,
  required Tarea tarea,
  required List<Color> coloresDisponibles,
}) {
  TextEditingController descripcionController = TextEditingController();
  TextEditingController profesorController = TextEditingController();
  TextEditingController creditosController = TextEditingController();
  TextEditingController nrcController = TextEditingController();
  String prioridadSeleccionada = "alta"; // o "media" o "baja"

  TextEditingController tareaController = TextEditingController(
    text: tarea.title,
  );
  Color tempColor = tarea.color;

  return showDialog<Tarea>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tareaController,
                  decoration: const InputDecoration(hintText: 'Edita tu tarea'),
                ),
                const SizedBox(height: 10),
                const Text('Selecciona un color'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children:
                      coloresDisponibles.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempColor = color;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border:
                                  tempColor == color
                                      ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                      : null,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (tareaController.text.isNotEmpty) {
                    Navigator.pop(
                      context,
                      Tarea(
                        title: tareaController.text,
                        descripcion:
                            descripcionController
                                .text, // Asegúrate de definir el controlador para la descripción
                        profesor:
                            profesorController
                                .text, // Asegúrate de definir el controlador para el profesor
                        creditos:
                            int.tryParse(creditosController.text) ??
                            0, // Asegúrate de tener el controlador de créditos
                        nrc:
                            int.tryParse(nrcController.text) ??
                            0, // Asegúrate de tener el controlador para el NRC
                        prioridad:
                            prioridadSeleccionada, // Asegúrate de que prioridadSeleccionada tenga un valor como "alta", "media" o "baja"
                        color: tempColor,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
