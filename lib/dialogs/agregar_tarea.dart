import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(Tarea, String) onSave;
  final DateTime initialDate;
  final List<Color> availableColors;

  const AddTaskDialog({
    super.key,
    required this.onSave,
    required this.initialDate,
    required this.availableColors,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late TextEditingController tareaController;
  late TextEditingController materia;
  late TextEditingController descripcionController;
  late TextEditingController profesorController;
  late TextEditingController creditosController;
  late TextEditingController nrcController;
  late Color colorSeleccionado;
  late int selectedHour;
  late DateTime selectedDate;
  late String prioridadSeleccionada;

  @override
  void initState() {
    super.initState();
    tareaController = TextEditingController();
    materia = TextEditingController();
    descripcionController = TextEditingController();
    profesorController = TextEditingController();
    creditosController = TextEditingController();
    nrcController = TextEditingController();
    colorSeleccionado = widget.availableColors[0];
    if (TimeOfDay.now().hour >= 23) {
      selectedHour = 0; // Reiniciar a 0 si es mayor a 23
    } else {
      selectedHour = TimeOfDay.now().hour + 1; // Usar hora actual
    }
    // selectedHour = TimeOfDay.now().hour + 1;
    selectedDate = widget.initialDate;
    prioridadSeleccionada = 'Media';
  }

  @override
  void dispose() {
    tareaController.dispose();
    materia.dispose();
    descripcionController.dispose();
    profesorController.dispose();
    creditosController.dispose();
    nrcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Tarea"),
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
              decoration: const InputDecoration(hintText: "Número de créditos"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              maxLength: 4,
              controller: nrcController,
              decoration: const InputDecoration(hintText: "NRC"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            const Text('Seleccione la prioridad de la tarea'),
            DropdownButton<String>(
              value: prioridadSeleccionada,
              onChanged: (value) {
                if (value != null) {
                  setState(() => prioridadSeleccionada = value);
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() => selectedDate = pickedDate);
                }
              },
              child: Text(
                "Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
              ),
            ),
            DropdownButton<int>(
              value: selectedHour,
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedHour = value);
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
            Wrap(
              spacing: 10,
              children:
                  widget.availableColors
                      .map(
                        (color) => GestureDetector(
                          onTap:
                              () => setState(() => colorSeleccionado = color),
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
              final nuevaTarea = Tarea(
                id: '',
                title: tareaController.text,
                materia: materia.text,
                descripcion: descripcionController.text,
                profesor: profesorController.text,
                creditos: int.tryParse(creditosController.text) ?? 0,
                nrc: int.tryParse(nrcController.text) ?? 0,
                prioridad: prioridadSeleccionada,
                color: colorSeleccionado,
                completada: false,
                fechaCreacion: DateTime.now(),
              );

              final clave = _formatDateKey(selectedDate, selectedHour);
              debugPrint(
                'Guardando tarea con fecha: $clave',
              ); // Para depuración
              widget.onSave(nuevaTarea, clave);
              Navigator.pop(context);
            }
          },
          child: const Text("Guardar"),
        ),
      ],
    );
  }

  String _formatDateKey(DateTime date, int hour) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${hour.toString().padLeft(2, '0')}';
  }
}

Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Tarea, String) onSave,
  required DateTime initialDate,
  required List<Color> availableColors,
}) async {
  await showDialog(
    context: context,
    builder:
        (context) => AddTaskDialog(
          onSave: onSave,
          initialDate: initialDate,
          availableColors: availableColors,
        ),
  );
}
