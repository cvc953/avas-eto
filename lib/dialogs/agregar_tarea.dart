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
  late TextEditingController _descripcionController;
  late Color _colorSeleccionado;
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  late String _prioridadSeleccionada;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tareaController = TextEditingController();
    _descripcionController = TextEditingController();
    // Seleccionar un color aleatorio
    _colorSeleccionado =
        widget.availableColors[DateTime.now().millisecond %
            widget.availableColors.length];
    _selectedTime = _calculateInitialTime();
    _selectedDate = widget.initialDate;
    _prioridadSeleccionada = 'Media';
  }

  TimeOfDay _calculateInitialTime() {
    final now = TimeOfDay.now();
    final nextHour = now.hour >= 23 ? 0 : now.hour + 1;
    return TimeOfDay(hour: nextHour, minute: 0);
  }

  @override
  void dispose() {
    _tareaController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final nuevaTarea = Tarea(
        id: '', // Se asignará al guardar
        title: _tareaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        prioridad: _prioridadSeleccionada.toString(),
        color: _colorSeleccionado,
        completada: false,
        fechaCreacion: DateTime.now(),
        fechaVencimiento: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        fechaCompletada: DateTime(0),
      );

      final clave = _formatDateKey(_selectedDate, _selectedTime);
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

  String _formatDateKey(DateTime date, TimeOfDay time) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}-${time.hour.toString().padLeft(2, '0')}'
        '-${time.minute.toString().padLeft(2, '0')}';
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
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  hintText: "Detalles de la tarea",
                ),
                maxLines: 2,
                maxLength: 200,
              ),

              const SizedBox(height: 16),
              const Text(
                'Prioridad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton(
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
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (pickedTime != null && mounted) {
                          setState(() => _selectedTime = pickedTime);
                        }
                      },
                      child: Text(
                        "Hora: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.white),
                      ),
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
                                color: Colors.black.withValues(alpha: 0.1),
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
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveTask,
          child:
              _isSaving
                  ? const CircularProgressIndicator()
                  : const Text(
                    "Guardar",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
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
