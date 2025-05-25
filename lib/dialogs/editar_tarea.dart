import 'package:flutter/material.dart';
import '../models/tarea.dart';

Future<Tarea?> mostrarDialogoEditarTarea({
  required BuildContext context,
  required Tarea tarea,
  required List<Color> coloresDisponibles,
}) async {
  TextEditingController tareaController = TextEditingController(
    text: tarea.title,
  );
  TextEditingController descripcionController = TextEditingController(
    text: tarea.descripcion,
  );
  TextEditingController profesorController = TextEditingController(
    text: tarea.profesor,
  );
  TextEditingController creditosController = TextEditingController(
    text: tarea.creditos.toString(),
  );
  TextEditingController nrcController = TextEditingController(
    text: tarea.nrc.toString(),
  );

  Color colorSeleccionado = tarea.color;
  String prioridadSeleccionada = tarea.prioridad;
  int selectedHour =
      12; // Hora por defecto, podrías extraerla de la clave si es necesario
  DateTime selectedDate = DateTime.now(); // Fecha por defecto

  return await showDialog<Tarea>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Editar Tarea"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tareaController,
                    decoration: const InputDecoration(
                      hintText: "Nombre de la materia",
                    ),
                  ),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(hintText: "Descripción"),
                  ),
                  TextField(
                    controller: profesorController,
                    decoration: const InputDecoration(hintText: "Profesor"),
                  ),
                  TextField(
                    maxLength: 1,
                    controller: creditosController,
                    decoration: const InputDecoration(
                      hintText: "Número de créditos",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    maxLength: 4,
                    controller: nrcController,
                    decoration: const InputDecoration(hintText: "NRC"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Text('Seleccione la prioridad de la tarea'),
                  DropdownButton<String>(
                    value: prioridadSeleccionada,
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => prioridadSeleccionada = value);
                      }
                    },
                    items:
                        ['Alta', 'Media', 'Baja']
                            .map(
                              (prioridad) => DropdownMenuItem(
                                value: prioridad,
                                child: Text(prioridad),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() => selectedDate = pickedDate);
                      }
                    },
                    child: Text(
                      "Fecha: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                    ),
                  ),
                  DropdownButton<int>(
                    value: selectedHour,
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedHour = value);
                      }
                    },
                    items: List.generate(
                      24,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text("${index.toString().padLeft(2, '0')}:00"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Seleccione un color:'),
                  Wrap(
                    spacing: 10,
                    children:
                        coloresDisponibles
                            .map(
                              (color) => GestureDetector(
                                onTap:
                                    () => setStateDialog(
                                      () => colorSeleccionado = color,
                                    ),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border:
                                        colorSeleccionado == color
                                            ? Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  if (tareaController.text.isNotEmpty) {
                    final tareaEditada = tarea.copyWith(
                      title: tareaController.text,
                      descripcion: descripcionController.text,
                      profesor: profesorController.text,
                      creditos: int.tryParse(creditosController.text) ?? 0,
                      nrc: int.tryParse(nrcController.text) ?? 0,
                      prioridad: prioridadSeleccionada,
                      color: colorSeleccionado,
                    );
                    Navigator.pop(context, tareaEditada);
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    },
  );
}
