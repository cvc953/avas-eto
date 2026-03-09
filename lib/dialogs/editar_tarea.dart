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
                        // Bottom sheet style for editing
                        return Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF121212),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                                      decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const Text('Editar Tarea', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _tareaController,
                                    decoration: const InputDecoration(labelText: 'Tarea*', hintText: 'Ej: Hacer presentación'),
                                    maxLength: 50,
                                    validator: (value) => value?.trim().isEmpty ?? true ? 'Este campo es requerido' : null,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _descripcionController,
                                    decoration: const InputDecoration(labelText: 'Descripción', hintText: 'Detalles de la tarea'),
                                    maxLines: 2,
                                    maxLength: 200,
                                  ),
                                  const SizedBox(height: 12),

                                  // Priority and Date side-by-side
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Prioridad:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: _prioridadSeleccionada,
                                                  dropdownColor: Colors.grey[900],
                                                  onChanged: (value) {
                                                    if (value != null) setState(() => _prioridadSeleccionada = value);
                                                  },
                                                  items: ['Alta', 'Media', 'Baja'].map((prioridad) => DropdownMenuItem(value: prioridad, child: Text(prioridad, style: const TextStyle(color: Colors.white)))).toList(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            const SizedBox(height: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[850], padding: const EdgeInsets.symmetric(vertical: 12)),
                                              onPressed: () async {
                                                final pickedDate = await showDatePicker(
                                                  context: context,
                                                  initialDate: _selectedDate,
                                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                                );
                                                if (pickedDate != null && mounted) setState(() => _selectedDate = pickedDate);
                                              },
                                              child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[850], padding: const EdgeInsets.symmetric(vertical: 12)),
                                        onPressed: () async {
                                          final pickedTime = await showTimePicker(context: context, initialTime: _selectedTime);
                                          if (pickedTime != null && mounted) setState(() => _selectedTime = pickedTime);
                                        },
                                        child: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                                          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
                                          onPressed: _isSaving ? null : _saveTask,
                                          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.onDelete != null) ...[
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _isSaving ? null : () {
                                        Navigator.pop(context);
                                        widget.onDelete!();
                                      },
                                      child: const Text('Eliminar Tarea', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
