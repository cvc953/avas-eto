import 'package:flutter/material.dart';
import '../models/tarea.dart';

Future<Map<String, dynamic>?> mostrarDialogoEditarTarea({
  required BuildContext context,
  required Tarea tarea,
  required List<Color> coloresDisponibles,
  required String horaActual,
  required DateTime fechaActual, // Recibir fecha actual como parámetro
}) async {
  // Convertir la hora actual a entero
  int horaInicial = int.tryParse(horaActual) ?? 12;

  // Controladores con los valores actuales
  final tareaController = TextEditingController(text: tarea.title);
  final materia = TextEditingController(text: tarea.materia);
  final descripcionController = TextEditingController(text: tarea.descripcion);
  final profesorController = TextEditingController(text: tarea.profesor);
  final creditosController = TextEditingController(
    text: tarea.creditos.toString(),
  );
  final nrcController = TextEditingController(text: tarea.nrc.toString());

  // Estado del diálogo
  Color colorSeleccionado = tarea.color;
  String prioridadSeleccionada = tarea.prioridad;
  int selectedHour = horaInicial;
  DateTime selectedDate = fechaActual; // Usar la fecha actual de la tarea

  return await showDialog<Map<String, dynamic>>(
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
                    decoration: const InputDecoration(hintText: "tarea"),
                  ),
                  TextField(
                    controller: materia,
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
                        ['Alta', 'Media', 'Baja'].map((prioridad) {
                          return DropdownMenuItem(
                            value: prioridad,
                            child: Text(prioridad),
                          );
                        }).toList(),
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
                        coloresDisponibles.map((color) {
                          return GestureDetector(
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
                          );
                        }).toList(),
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
                      materia: materia.text,
                      descripcion: descripcionController.text,
                      profesor: profesorController.text,
                      creditos: int.tryParse(creditosController.text) ?? 0,
                      nrc: int.tryParse(nrcController.text) ?? 0,
                      prioridad: prioridadSeleccionada,
                      color: colorSeleccionado,
                    );
                    Navigator.pop(context, {
                      'tarea': tareaEditada,
                      'hora': selectedHour,
                      'fecha': selectedDate,
                    });
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
