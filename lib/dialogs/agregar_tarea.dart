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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tareaController;
  late TextEditingController _materiaController;
  late TextEditingController _descripcionController;
  late TextEditingController _profesorController;
  late TextEditingController _creditosController;
  late TextEditingController _nrcController;
  late Color _colorSeleccionado;
  late int _selectedHour;
  late DateTime _selectedDate;
  late String _prioridadSeleccionada;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tareaController = TextEditingController();
    _materiaController = TextEditingController();
    _descripcionController = TextEditingController();
    _profesorController = TextEditingController();
    _creditosController = TextEditingController();
    _nrcController = TextEditingController();
    _colorSeleccionado = widget.availableColors.first;
    _selectedHour = _calculateInitialHour();
    _selectedDate = widget.initialDate;
    _prioridadSeleccionada = 'Media';
  }

  int _calculateInitialHour() {
    final now = TimeOfDay.now();
    return now.hour >= 23 ? 0 : now.hour + 1;
  }

  @override
  void dispose() {
    _tareaController.dispose();
    _materiaController.dispose();
    _descripcionController.dispose();
    _profesorController.dispose();
    _creditosController.dispose();
    _nrcController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final nuevaTarea = Tarea(
        id: '', // Se asignará al guardar
        title: _tareaController.text.trim(),
        materia: _materiaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        profesor: _profesorController.text.trim(),
        creditos: int.parse(_creditosController.text),
        nrc: int.parse(_nrcController.text),
        prioridad: _prioridadSeleccionada,
        color: _colorSeleccionado,
        completada: false,
        fechaCreacion: DateTime.now(),
      );

      final clave = _formatDateKey(_selectedDate, _selectedHour);
      widget.onSave(nuevaTarea, clave);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDateKey(DateTime date, int hour) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}-${hour.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Tarea", textAlign: TextAlign.center),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tareaController,
                decoration: const InputDecoration(
                  labelText: "Tarea*",
                  hintText: "Ej: Hacer presentación",
                ),
                maxLength: 50,
                validator:
                    (value) =>
                        value?.trim().isEmpty ?? true
                            ? 'Este campo es requerido'
                            : null,
              ),
              TextFormField(
                controller: _materiaController,
                decoration: const InputDecoration(
                  labelText: "Materia*",
                  hintText: "Ej: Matemáticas",
                ),
                maxLength: 50,
                validator:
                    (value) =>
                        value?.trim().isEmpty ?? true
                            ? 'Este campo es requerido'
                            : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  hintText: "Detalles de la tarea",
                ),
                maxLines: 2,
                maxLength: 200,
              ),
              TextFormField(
                controller: _profesorController,
                decoration: const InputDecoration(
                  labelText: "Profesor",
                  hintText: "Nombre del profesor",
                ),
                maxLength: 50,
              ),
              TextFormField(
                controller: _creditosController,
                decoration: const InputDecoration(
                  labelText: "Créditos*",
                  hintText: "Número de créditos",
                ),
                keyboardType: TextInputType.number,
                maxLength: 1,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Requerido';
                  final num = int.tryParse(value!);
                  if (num == null || num < 0 || num > 9) {
                    return 'Entre 0 y 9';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nrcController,
                decoration: const InputDecoration(
                  labelText: "NRC*",
                  hintText: "Código NRC",
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Requerido';
                  final num = int.tryParse(value!);
                  if (num == null || num < 0) return 'Número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Prioridad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: _prioridadSeleccionada,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _prioridadSeleccionada = value);
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() => _selectedDate = pickedDate);
                        }
                      },
                      child: Text(
                        "Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedHour,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedHour = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: "Hora",
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(24, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text("${index.toString().padLeft(2, '0')}:00"),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Color:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    widget.availableColors.map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _colorSeleccionado = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border:
                                _colorSeleccionado == color
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveTask,
          child:
              _isSaving
                  ? const CircularProgressIndicator()
                  : const Text("Guardar"),
        ),
      ],
    );
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

/*import 'package:flutter/material.dart';
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
}*/
