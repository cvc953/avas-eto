import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(Tarea, String) onSave;
  final DateTime initialDate;

  const AddTaskDialog({
    super.key,
    required this.onSave,
    required this.initialDate,
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
    _colorSeleccionado = Colors.blueAccent;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor =
        isDark ? const Color(0xFF121212) : Theme.of(context).cardColor;
    final titleColor =
        Theme.of(context).textTheme.titleLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        (isDark ? Colors.white70 : Colors.black54);
    final iconColor =
        Theme.of(context).iconTheme.color ??
        (isDark ? Colors.white : Colors.black87);

    Color _priorityColor(String p) {
      switch (p) {
        case 'Alta':
          return const Color(0xFFFF5F6D);
        case 'Media':
          return const Color(0xFFFFBC1F);
        case 'Baja':
          return const Color(0xFF00D4B5);
        default:
          return Colors.grey;
      }
    }

    // Bottom sheet style content
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Nueva Tarea',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tareaController,
                decoration: const InputDecoration(
                  labelText: 'Tarea*',
                  hintText: 'Ej: Hacer presentación',
                ),
                maxLength: 50,
                validator:
                    (value) =>
                        value?.trim().isEmpty ?? true
                            ? 'Este campo es requerido'
                            : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalles de la tarea',
                ),
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 12),

              // Compact icons: date, priority, then time (time moved to the right)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Date icon + small label
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Seleccionar fecha',
                        icon: Icon(Icons.calendar_today, color: iconColor),
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
                          if (pickedDate != null && mounted)
                            setState(() => _selectedDate = pickedDate);
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM').format(_selectedDate),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Priority icon + small label
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Seleccionar prioridad',
                        icon: Icon(
                          Icons.flag,
                          color: _priorityColor(_prioridadSeleccionada),
                        ),
                        onPressed: () async {
                          final selected = await showDialog<String?>(
                            context: context,
                            builder:
                                (context) => SimpleDialog(
                                  backgroundColor: sheetColor,
                                  title: Text(
                                    'Prioridad',
                                    style: TextStyle(color: titleColor),
                                  ),
                                  children:
                                      ['Alta', 'Media', 'Baja', 'Ninguna']
                                          .map(
                                            (p) => SimpleDialogOption(
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(context, p),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.flag,
                                                    color: _priorityColor(p),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    p,
                                                    style: TextStyle(
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                          );
                          if (selected != null && mounted)
                            setState(() => _prioridadSeleccionada = selected);
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: _priorityColor(_prioridadSeleccionada),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _prioridadSeleccionada,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Time icon + small label (moved to the right)
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Seleccionar hora',
                        icon: Icon(Icons.access_time, color: iconColor),
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (pickedTime != null && mounted)
                            setState(() => _selectedTime = pickedTime);
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: titleColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSaving ? null : _saveTask,
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Guardar',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Tarea, String) onSave,
  required DateTime initialDate,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => AddTaskDialog(onSave: onSave, initialDate: initialDate),
  );
}
