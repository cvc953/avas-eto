import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';

class EditTaskDialog extends StatefulWidget {
  final Tarea tarea;
  final Function(Tarea, String) onSave;
  final List<Color> availableColors;

  const EditTaskDialog({
    super.key,
    required this.tarea,
    required this.onSave,
    required this.availableColors,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
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
    _tareaController = TextEditingController(text: widget.tarea.title);
    _descripcionController = TextEditingController(
      text: widget.tarea.descripcion,
    );
    _colorSeleccionado = widget.tarea.color;
    _selectedTime = TimeOfDay(
      hour: widget.tarea.fechaVencimiento.hour,
      minute: widget.tarea.fechaVencimiento.minute,
    );
    _selectedDate = widget.tarea.fechaVencimiento;
    _prioridadSeleccionada = widget.tarea.prioridad;
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
      final tareaEditada = widget.tarea.copyWith(
        title: _tareaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        prioridad: _prioridadSeleccionada,
        color: _colorSeleccionado,
        fechaVencimiento: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      );

      final clave = _formatDateKey(_selectedDate, _selectedTime);
      widget.onSave(tareaEditada, clave);

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
      title: const Text("Editar Tarea", textAlign: TextAlign.center),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                    child: Text(
                      'Fecha:\n ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() => _selectedTime = pickedTime);
                      }
                    },
                    child: Text(
                      "Hora:\n ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(color: Colors.white),
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
                      final isSelected = _colorSeleccionado == color;
                      return GestureDetector(
                        onTap: () => setState(() => _colorSeleccionado = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border:
                                isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
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
          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveTask,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
        ),
      ],
    );
  }
}
