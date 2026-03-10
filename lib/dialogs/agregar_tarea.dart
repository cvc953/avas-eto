import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/tarea.dart';
import '../services/inicia_con_google.dart';
import '../services/drive_service.dart';

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
  late TimeOfDay _selectedStartTime;
  late TimeOfDay _selectedEndTime;
  late DateTime _selectedDate;
  late String _prioridadSeleccionada;
  bool _todoElDia = false;
  final List<Map<String, dynamic>> _adjuntos = [];
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tareaController = TextEditingController();
    _descripcionController = TextEditingController();
    _colorSeleccionado = Colors.blueAccent;
    _selectedStartTime = _calculateInitialTime();
    _selectedEndTime = _calculateEndTime(_selectedStartTime);
    _selectedDate = widget.initialDate;
    _prioridadSeleccionada = 'Media';
  }

  TimeOfDay _calculateInitialTime() {
    final now = TimeOfDay.now();
    final nextHour = now.hour >= 23 ? 0 : now.hour + 1;
    return TimeOfDay(hour: nextHour, minute: 0);
  }

  TimeOfDay _calculateEndTime(TimeOfDay startTime) {
    final startMinutes = (startTime.hour * 60) + startTime.minute;
    final endMinutes = (startMinutes + 60) % (24 * 60);
    return TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
  }

  DateTime _dateTimeFromTimeOfDay(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int _calculateDurationMinutes() {
    if (_todoElDia) return 24 * 60;

    final start = _dateTimeFromTimeOfDay(_selectedDate, _selectedStartTime);
    final end = _dateTimeFromTimeOfDay(_selectedDate, _selectedEndTime);
    return end.difference(start).inMinutes;
  }

  String _formatTimeLabel(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _buildScheduleSummary() {
    if (_todoElDia) return 'Todo el dia';

    final durationMinutes = _calculateDurationMinutes();
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final durationLabel =
        hours > 0
            ? minutes > 0
                ? '${hours}h ${minutes}m'
                : '${hours}h'
            : '${minutes}m';

    return '${_formatTimeLabel(_selectedStartTime)} - ${_formatTimeLabel(_selectedEndTime)} · $durationLabel';
  }

  Future<void> _openScheduleSheet() async {
    DateTime tempDate = _selectedDate;
    TimeOfDay tempStart = _selectedStartTime;
    TimeOfDay tempEnd = _selectedEndTime;
    bool tempAllDay = _todoElDia;

    String buildTempSummary() {
      if (tempAllDay) return 'Todo el dia';
      final start = _dateTimeFromTimeOfDay(tempDate, tempStart);
      final end = _dateTimeFromTimeOfDay(tempDate, tempEnd);
      final durationMinutes = end.difference(start).inMinutes;
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      final durationLabel =
          hours > 0
              ? minutes > 0
                  ? '${hours}h ${minutes}m'
                  : '${hours}h'
              : '${minutes}m';
      return '${_formatTimeLabel(tempStart)} - ${_formatTimeLabel(tempEnd)} · $durationLabel';
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Duracion',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 0,
                            child: ListTile(
                              title: const Text('Fecha'),
                              subtitle: Text(
                                DateFormat('EEE, MMM d', 'es').format(tempDate),
                              ),
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: tempDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (pickedDate != null) {
                                  setSheetState(() => tempDate = pickedDate);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            child: ListTile(
                              title: const Text('Hora'),
                              subtitle: Text(
                                tempAllDay
                                    ? 'Todo el dia'
                                    : '${_formatTimeLabel(tempStart)} - ${_formatTimeLabel(tempEnd)}',
                              ),
                              onTap:
                                  tempAllDay
                                      ? null
                                      : () async {
                                        final start = await showTimePicker(
                                          context: sheetContext,
                                          initialTime: tempStart,
                                        );
                                        if (start == null) return;
                                        final end = await showTimePicker(
                                          context: sheetContext,
                                          initialTime: tempEnd,
                                        );
                                        if (end == null) return;
                                        setSheetState(() {
                                          tempStart = start;
                                          tempEnd = end;
                                        });
                                      },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Todo el dia'),
                      value: tempAllDay,
                      onChanged: (value) {
                        setSheetState(() => tempAllDay = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      buildTempSummary(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final start = _dateTimeFromTimeOfDay(
                            tempDate,
                            tempStart,
                          );
                          final end = _dateTimeFromTimeOfDay(tempDate, tempEnd);
                          if (!tempAllDay && !end.isAfter(start)) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La hora final debe ser posterior a la hora de inicio.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedDate = tempDate;
                            _selectedStartTime = tempStart;
                            _selectedEndTime = tempEnd;
                            _todoElDia = tempAllDay;
                            _hasChanges = true;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      final fechaInicio =
          _todoElDia
              ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              )
              : _dateTimeFromTimeOfDay(_selectedDate, _selectedStartTime);
      final fechaVencimiento =
          _todoElDia
              ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                23,
                59,
              )
              : _dateTimeFromTimeOfDay(_selectedDate, _selectedEndTime);

      if (!_todoElDia && !fechaVencimiento.isAfter(fechaInicio)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La hora final debe ser posterior a la hora de inicio.',
              ),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final duracionMinutos =
          fechaVencimiento.difference(fechaInicio).inMinutes;

      // If user granted Drive access, upload attachments and replace entries with Drive references.
      await _maybeUploadAdjuntosToDrive(_adjuntos);

      final nuevaTarea = Tarea(
        id: '', // Se asignará al guardar
        title: _tareaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        prioridad: _prioridadSeleccionada.toString(),
        color: _colorSeleccionado,
        completada: false,
        fechaCreacion: DateTime.now(),
        fechaInicio: fechaInicio,
        fechaVencimiento: fechaVencimiento,
        duracionMinutos: duracionMinutos,
        todoElDia: _todoElDia,
        adjuntos: _adjuntos,
        fechaCompletada: DateTime(0),
      );

      final clave = _formatDateKey(
        fechaVencimiento,
        TimeOfDay(hour: fechaVencimiento.hour, minute: fechaVencimiento.minute),
      );
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

  void _markChanged() {
    if (_hasChanges) return;
    setState(() => _hasChanges = true);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        if (file.path == null) continue;
        _adjuntos.add({
          'path': file.path,
          'name': file.name,
          'size': file.size,
        });
      }
      _hasChanges = true;
    });
  }

  Future<void> _pickPhotoGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );

    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        if (file.path == null) continue;
        _adjuntos.add({
          'path': file.path,
          'name': file.name,
          'size': file.size,
        });
      }
      _hasChanges = true;
    });
  }

  void _showCameraUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tomar foto requiere el plugin de camara. Activalo cuando haya conexion para instalar dependencias.',
        ),
      ),
    );
  }

  Future<void> _showAttachmentOptions() async {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Seleccionar archivos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAttachment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _showCameraUnavailableMessage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir foto de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotoGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      _adjuntos.removeAt(index);
      _hasChanges = true;
    });
  }

  bool _isImageAttachment(Map<String, dynamic> item) {
    final raw =
        ((item['name'] as String?) ?? (item['path'] as String?) ?? '')
            .toLowerCase();
    return raw.endsWith('.png') ||
        raw.endsWith('.jpg') ||
        raw.endsWith('.jpeg') ||
        raw.endsWith('.gif') ||
        raw.endsWith('.webp') ||
        raw.endsWith('.bmp');
  }

  Widget _buildAttachmentWidget(Map<String, dynamic> item, int index) {
    final name = (item['name'] as String?) ?? 'archivo';
    final path = item['path'] as String?;

    if (_isImageAttachment(item) && path != null && path.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openAttachment(item),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 88,
                    height: 88,
                    color: Theme.of(context).dividerColor,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => _removeAttachment(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InputChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(name, overflow: TextOverflow.ellipsis),
      ),
      onPressed: () => _openAttachment(item),
      onDeleted: () => _removeAttachment(index),
    );
  }

  Future<void> _openAttachment(Map<String, dynamic> item) async {
    final path = item['path'] as String?;
    if (path == null || path.isEmpty) return;

    if (_isImageAttachment(item)) {
      _openImagePreview(path, (item['name'] as String?) ?? 'Imagen');
      return;
    }

    // Prefer native Android FileProvider open via MethodChannel to let OS choose the app.
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.cvc.avas_eto/open_file');
        final res = await channel.invokeMethod('openFile', {'path': path});
        debugPrint('openAttachment: platform openFile result=$res');
        return;
      } catch (e, st) {
        debugPrint('openAttachment: platform openFile failed: $e\n$st');
        // fallthrough to url_launcher fallback
      }
    }

    final uri = Uri.file(path);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo adjunto.')),
      );
    }
  }

  Future<void> _maybeUploadAdjuntosToDrive(
    List<Map<String, dynamic>> adjuntos,
  ) async {
    try {
      final token = await getGoogleAccessToken(requestDrive: true);
      if (token == null) return;

      for (var i = 0; i < adjuntos.length; i++) {
        final it = adjuntos[i];
        final path = it['path'] as String?;
        if (path == null) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final id = await uploadFileToDrive(file, token);
        if (id != null) {
          adjuntos[i] = {
            'driveId': id,
            'name': it['name'] ?? file.uri.pathSegments.last,
            'size': it['size'] ?? await file.length(),
          };
        }
      }
    } catch (e) {
      debugPrint('Error uploading attachments to Drive: $e');
    }
  }

  Future<void> _openImagePreview(String path, String title) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('No se pudo cargar la imagen');
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({required Widget icon, required Widget label}) {
    return Column(children: [icon, const SizedBox(height: 4), label]);
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
          return const Color(0xFFFF6D00);
        case 'Media':
          return const Color(0xFF1565C0);
        case 'Baja':
          return const Color(0xFFFBC02D);
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
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
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
              Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tareaController,
                      onChanged: (_) => _markChanged(),
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
                      onChanged: (_) => _markChanged(),
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
                      minLines: 1,
                      maxLines: null,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              if (_adjuntos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_adjuntos.length, (index) {
                    final item = _adjuntos[index];
                    return _buildAttachmentWidget(item, index);
                  }),
                ),
              ],
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _buildActionItem(
                        icon: IconButton(
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
                                      'Importancia',
                                      style: TextStyle(color: titleColor),
                                    ),
                                    children:
                                        ['Alta', 'Media', 'Baja', 'Ninguna']
                                            .map(
                                              (p) => SimpleDialogOption(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      p,
                                                    ),
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
                              setState(() {
                                _prioridadSeleccionada = selected;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
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
                      ),
                      const SizedBox(width: 10),
                      _buildActionItem(
                        icon: IconButton(
                          tooltip: 'Horario',
                          icon: Icon(Icons.access_time, color: iconColor),
                          onPressed: _openScheduleSheet,
                        ),
                        label: Text(
                          _buildScheduleSummary(),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildActionItem(
                        icon: IconButton(
                          tooltip: 'Adjuntar',
                          icon: Icon(Icons.attach_file, color: iconColor),
                          onPressed: _showAttachmentOptions,
                        ),
                        label: Text(
                          _adjuntos.isEmpty
                              ? 'Adjuntar'
                              : '${_adjuntos.length} archivo(s)',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

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
