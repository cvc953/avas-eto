import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/tarea.dart';
import '../services/attachment_storage_service.dart';
import '../services/inicia_con_google.dart';
import '../theme/theme.dart';
import 'task_dialog_ui.dart';
import '../utils/app_toast.dart';

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
  static const int _maxAttachmentBytes = 15 * 1024 * 1024;
  static const Set<String> _blockedCompressedExtensions = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'xz',
  };

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
  final AttachmentStorageService _attachmentStorageService =
      const AttachmentStorageService();
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

  int _timeOfDayToMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  DateTime _resolveEndDateTime(
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    final endDateTime = _dateTimeFromTimeOfDay(date, endTime);
    if (_timeOfDayToMinutes(endTime) < _timeOfDayToMinutes(startTime)) {
      return endDateTime.add(const Duration(days: 1));
    }
    return endDateTime;
  }

  int _calculateDurationMinutes() {
    if (_todoElDia) return 24 * 60;

    final start = _dateTimeFromTimeOfDay(_selectedDate, _selectedStartTime);
    final end = _resolveEndDateTime(
      _selectedDate,
      _selectedStartTime,
      _selectedEndTime,
    );
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
      final end = _resolveEndDateTime(tempDate, tempStart, tempEnd);
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
                      activeColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withAlpha(110),
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
                          final end = _resolveEndDateTime(
                            tempDate,
                            tempStart,
                            tempEnd,
                          );
                          if (!tempAllDay && !end.isAfter(start)) {
                            AppToast.warning(
                              sheetContext,
                              'La hora final debe ser posterior a la hora de inicio.',
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
              : _resolveEndDateTime(
                _selectedDate,
                _selectedStartTime,
                _selectedEndTime,
              );

      if (!_todoElDia && !fechaVencimiento.isAfter(fechaInicio)) {
        if (mounted) {
          AppToast.warning(
            context,
            'La hora final debe ser posterior a la hora de inicio.',
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final duracionMinutos =
          fechaVencimiento.difference(fechaInicio).inMinutes;

      final hasLocalAttachments = _adjuntos.any(
        (attachment) => attachment['path'] is String,
      );
      String? driveToken;
      if (hasLocalAttachments) {
        driveToken = await getGoogleAccessToken(
          requestDrive: true,
          interactiveScopePrompt: false,
        );
        if (mounted && driveToken == null) {
          AppToast.warning(
            context,
            'Los adjuntos se guardaron localmente. La subida a Drive quedara pendiente hasta autorizar el acceso desde Mas opciones.',
          );
        }
      }

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

      if (mounted && hasLocalAttachments && driveToken != null) {
        AppToast.success(
          context,
          'La tarea se guardo y los adjuntos se subiran en segundo plano.',
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al guardar: ${e.toString()}');
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

    final allowedFiles = _filterAllowedFiles(result.files);
    if (allowedFiles.isEmpty) return;

    final pending = await _attachmentStorageService.persistPickedFiles(
      allowedFiles,
    );
    if (!mounted || pending.isEmpty) return;

    setState(() {
      _adjuntos.addAll(pending);
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

    final allowedFiles = _filterAllowedFiles(result.files);
    if (allowedFiles.isEmpty) return;

    final pending = await _attachmentStorageService.persistPickedFiles(
      allowedFiles,
    );
    if (!mounted || pending.isEmpty) return;

    setState(() {
      _adjuntos.addAll(pending);
      _hasChanges = true;
    });
  }

  Future<void> _takePhoto() async {
    if (!Platform.isAndroid) {
      if (mounted) {
        AppToast.info(context, 'Tomar foto nativo esta disponible en Android.');
      }
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        AppToast.warning(context, 'Permiso de camara denegado.');
      }
      return;
    }

    try {
      const channel = MethodChannel('com.cvc.avas_eto/open_file');
      final path = await channel.invokeMethod<String>('takePhoto');
      if (path == null || path.isEmpty || !mounted) return;

      final rawFile = File(path);
      final size = await rawFile.length();
      if (size > _maxAttachmentBytes) {
        if (mounted) {
          AppToast.warning(
            context,
            'La foto supera 15 MB y no se puede adjuntar.',
          );
        }
        return;
      }

      final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final stablePath = await _attachmentStorageService.persistFilePath(
        path,
        fileName,
      );

      if (!mounted || stablePath == null || stablePath.isEmpty) return;

      setState(() {
        _adjuntos.add({'path': stablePath, 'name': fileName, 'size': size});
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo tomar la foto: $e');
      }
    }
  }

  List<PlatformFile> _filterAllowedFiles(List<PlatformFile> files) {
    int blockedCompressed = 0;
    int blockedLarge = 0;
    final allowed = <PlatformFile>[];

    for (final file in files) {
      final ext = (file.extension ?? '').toLowerCase();
      final isCompressed = _blockedCompressedExtensions.contains(ext);
      final isTooLarge = file.size > _maxAttachmentBytes;

      if (isCompressed) {
        blockedCompressed++;
        continue;
      }
      if (isTooLarge) {
        blockedLarge++;
        continue;
      }
      allowed.add(file);
    }

    if (!mounted) return allowed;

    if (blockedCompressed > 0) {
      AppToast.warning(
        context,
        'Se omitieron $blockedCompressed archivo(s) comprimido(s).',
      );
    }
    if (blockedLarge > 0) {
      AppToast.warning(
        context,
        'Se omitieron $blockedLarge archivo(s) por superar 15 MB.',
      );
    }

    return allowed;
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
                  _takePhoto();
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

  IconData _attachmentIconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (lower.endsWith('.xls') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.csv')) {
      return Icons.table_chart_rounded;
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    }
    if (lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.7z') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz')) {
      return Icons.folder_zip_rounded;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.m4a')) {
      return Icons.audio_file_rounded;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm')) {
      return Icons.video_file_rounded;
    }
    if (lower.endsWith('.txt') || lower.endsWith('.md')) {
      return Icons.text_snippet_rounded;
    }
    return Icons.insert_drive_file_rounded;
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
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 104,
                    height: 104,
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

    final icon = _attachmentIconFor(name);
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withAlpha(28),
        child: Icon(icon, size: 16, color: AppTheme.primaryColor),
      ),
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
      AppToast.error(context, 'No se pudo abrir el archivo adjunto.');
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

  Color _priorityColor(String prioridad) {
    switch (prioridad) {
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

  String _buildMetaLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dayDiff = selected.difference(today).inDays;

    final dateLabel =
        dayDiff == 0
            ? 'Hoy'
            : dayDiff == 1
            ? 'Manana'
            : DateFormat('EEE d MMM', 'es').format(_selectedDate);

    if (_todoElDia) return '$dateLabel · Todo el dia';
    return '$dateLabel · ${_buildScheduleSummary()}';
  }

  Future<void> _showPriorityPicker(Color sheetColor, Color titleColor) async {
    final selected = await showDialog<String?>(
      context: context,
      builder:
          (context) => SimpleDialog(
            backgroundColor: sheetColor,
            title: Text('Importancia', style: TextStyle(color: titleColor)),
            children:
                ['Alta', 'Media', 'Baja', 'Ninguna']
                    .map(
                      (p) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, p),
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: _priorityColor(p)),
                            const SizedBox(width: 12),
                            Text(p, style: TextStyle(color: titleColor)),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);

    return Form(
      key: _formKey,
      child: TaskDialogShell(
        title: 'Nueva tarea',
        trailing: [
          TaskDialogToolbarButton(
            icon: Icons.close_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskDialogMetaTile(
              icon: Icons.event_outlined,
              label: _buildMetaLabel(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tareaController,
              onChanged: (_) => _markChanged(),
              cursorColor: AppTheme.primaryColor,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
              ),
              decoration: const InputDecoration(
                hintText: '¿Que necesitas hacer?',
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              maxLength: 50,
              validator:
                  (value) =>
                      value?.trim().isEmpty ?? true
                          ? 'Este campo es requerido'
                          : null,
            ),
            Divider(height: 24, color: theme.dividerColor),
            TextFormField(
              controller: _descripcionController,
              onChanged: (_) => _markChanged(),
              cursorColor: AppTheme.primaryColor,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Descripcion',
                filled: false,
                fillColor: Colors.transparent,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              minLines: 3,
              maxLines: null,
              maxLength: 200,
            ),
            if (_adjuntos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_adjuntos.length, (index) {
                  final item = _adjuntos[index];
                  return _buildAttachmentWidget(item, index);
                }),
              ),
            ],
          ],
        ),
        footer: Row(
          children: [
            TaskDialogToolbarButton(
              icon: Icons.flag,
              color: _priorityColor(_prioridadSeleccionada),
              onPressed: () => _showPriorityPicker(theme.cardColor, titleColor),
            ),
            const SizedBox(width: 8),
            TaskDialogToolbarButton(
              icon: Icons.event_outlined,
              onPressed: _openScheduleSheet,
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                TaskDialogToolbarButton(
                  icon: Icons.attach_file_rounded,
                  onPressed: _showAttachmentOptions,
                ),
                if (_adjuntos.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_adjuntos.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: (_hasChanges && !_isSaving) ? _saveTask : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primaryColor.withAlpha(90),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_rounded),
              ),
            ),
          ],
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
