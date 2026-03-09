import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';

class EditTaskDialog extends StatefulWidget {
  final Tarea tarea;
  final Function(Tarea, String) onSave;
  final VoidCallback? onDelete;
  const EditTaskDialog({
    super.key,
    required this.tarea,
    required this.onSave,
    this.onDelete,
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
  late String _initialTitle;
  late String _initialDescripcion;
  late String _initialPrioridad;
  late DateTime _initialFechaVencimiento;
  bool _isSaving = false;

  Future<void> _confirmDelete() async {
    if (widget.onDelete == null || _isSaving) return;

    final confirmado =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: const Text('¿Seguro que deseas eliminar esta tarea?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmado || !mounted) return;
    widget.onDelete!();
  }

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
    _initialTitle = widget.tarea.title;
    _initialDescripcion = widget.tarea.descripcion;
    _initialPrioridad = widget.tarea.prioridad;
    _initialFechaVencimiento = widget.tarea.fechaVencimiento;
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

      // Call onSave which will close the dialog
      widget.onSave(tareaEditada, clave);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateKey(DateTime date, TimeOfDay time) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}-${time.hour.toString().padLeft(2, '0')}'
        '-${time.minute.toString().padLeft(2, '0')}';
  }

  bool get _hasChanges {
    final titleChanged = _tareaController.text.trim() != _initialTitle.trim();
    final descripcionChanged =
        _descripcionController.text.trim() != _initialDescripcion.trim();
    final prioridadChanged = _prioridadSeleccionada != _initialPrioridad;
    final fechaChanged =
        _selectedDate.year != _initialFechaVencimiento.year ||
        _selectedDate.month != _initialFechaVencimiento.month ||
        _selectedDate.day != _initialFechaVencimiento.day ||
        _selectedTime.hour != _initialFechaVencimiento.hour ||
        _selectedTime.minute != _initialFechaVencimiento.minute;

    return titleChanged ||
        descripcionChanged ||
        prioridadChanged ||
        fechaChanged;
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
                'Editar Tarea',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tareaController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tarea*',
                        hintText: 'Ej: Hacer presentación',
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLength: 50,
                      validator:
                          (value) =>
                              value?.trim().isEmpty ?? true
                                  ? 'Este campo es requerido'
                                  : null,
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    TextFormField(
                      controller: _descripcionController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Detalles de la tarea',
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 2,
                      maxLength: 200,
                    ),
                  ],
                ),
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
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null && mounted) {
                            setState(() => _selectedDate = pickedDate);
                          }
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
                          if (selected != null && mounted) {
                            setState(() => _prioridadSeleccionada = selected);
                          }
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
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null && mounted) {
                            setState(() => _selectedTime = pickedTime);
                          }
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
              const SizedBox(height: 12),
              const SizedBox(height: 18),
              if (_hasChanges)
                ElevatedButton(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSaving ? null : _confirmDelete,
                  child: const Text(
                    'Eliminar Tarea',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
