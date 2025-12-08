import 'package:ap/services/local_database.dart';
import 'package:ap/services/conectividad_service.dart';
import '../dialogs/agregar_tarea.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import '../widgets/buscar_tareas.dart';
import '../utils/tarea_helpers.dart';

class TareasInicio extends StatefulWidget {
  const TareasInicio({super.key});

  @override
  _TareasInicioState createState() => _TareasInicioState();
}

class _TareasInicioState extends State<TareasInicio> {
  // =============== PROPIEDADES ===============
  final List<Color> coloresDisponibles = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
  ];

  bool _loading = true;
  bool _isOnline = true;

  late final LocalStorageService _localStorage;
  late final ConectividadService _conectividadService;

  final LocalDatabase _localDb = LocalDatabase();
  final Map<String, List<Tarea>> _tareas = {};
  final Set<Tarea> _tareasExpandida = {};

  // =============== CICLO DE VIDA ===============
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _conectividadService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _localStorage = LocalStorageService(_localDb);
      _conectividadService = ConectividadService();

      _conectividadService.setupListener((isOnline) {
        setState(() => _isOnline = isOnline);
      });

      await _loadLocalTareas();
      await _setupFirestoreListener();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error inicializando: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // =============== LISTENERS Y DATOS ===============
  Future<void> _setupFirestoreListener() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore.instance
          .collection('tareas')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (!mounted) return;
              setState(() {
                _tareas.clear();
                for (var doc in snapshot.docs) {
                  _procesarDocumentoTarea(doc);
                }
              });
            },
            onError: (e) {
              debugPrint('Error en stream: $e');
            },
          );
    } catch (e) {
      debugPrint('Error setup Firestore: $e');
    }
  }

  void _procesarDocumentoTarea(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    try {
      final tarea = Tarea(
        id: doc.id,
        title: data['titulo'] ?? '',
        materia: data['materia'] ?? '',
        descripcion: data['descripcion'] ?? '',
        profesor: data['profesor'] ?? '',
        creditos: data['creditos'] ?? 0,
        nrc: data['nrc'] ?? 0,
        prioridad: data['prioridad'] ?? 'Media',
        color: Color(int.parse(data['color'] ?? '0xFFFF0000', radix: 16)),
        completada: data['completada'] ?? false,
        fechaCreacion: (data['creadoEn'] as Timestamp).toDate(),
      );

      final clave = data['fecha'] as String;
      _tareas.putIfAbsent(clave, () => []);
      if (!_tareas[clave]!.any((t) => t.id == tarea.id)) {
        _tareas[clave]!.add(tarea);
      }
    } catch (e) {
      debugPrint('Error procesando documento: $e');
    }
  }

  Future<void> _loadLocalTareas() async {
    try {
      final tareas = await _localStorage.getTareas();
      if (mounted) {
        setState(() {
          for (var tarea in tareas) {
            final hora = _obtenerHoraDeTarea(tarea);
            final clave = getTaskKey(tarea.fechaCreacion, int.parse(hora));
            _tareas.putIfAbsent(clave, () => []);
            if (!_tareas[clave]!.any((t) => t.id == tarea.id)) {
              _tareas[clave]!.add(tarea);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando tareas locales: $e');
    }
  }

  // =============== OPERACIONES CON TAREAS ===============
  Future<void> _guardarTarea(Tarea tarea) async {
    try {
      final hora = _obtenerHoraDeTarea(tarea);
      final clave = getTaskKey(tarea.fechaCreacion, int.parse(hora));

      if (mounted) {
        setState(() {
          _tareas.putIfAbsent(clave, () => []);
          if (!_tareas[clave]!.any((t) => t.id == tarea.id)) {
            _tareas[clave]!.add(tarea);
          }
        });
      }

      if (_isOnline) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('tareas')
              .add(tareaToFirestoreMap(tarea, clave)..['userId'] = user.uid);
        }
      }

      await _localStorage.saveTarea(tarea);
    } catch (e) {
      debugPrint('Error guardando: $e');
      _mostrarError('Error al guardar: ${e.toString()}');
    }
  }

  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    try {
      final tareaActualizada = tarea.copyWith(completada: completada);

      final entrada = _tareas.entries.firstWhere(
        (entry) => entry.value.contains(tarea),
      );

      if (mounted) {
        setState(() {
          final index = entrada.value.indexOf(tarea);
          if (index >= 0) {
            entrada.value[index] = tareaActualizada;
          }
        });
      }

      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update({'completada': completada});
      }

      await _localStorage.saveTarea(tareaActualizada);
    } catch (e) {
      debugPrint('Error marcando completada: $e');
    }
  }

  Future<void> _moverTarea(
    Tarea tarea,
    String claveVieja,
    String claveNueva,
    int index,
  ) async {
    try {
      if (mounted) {
        setState(() {
          _tareas[claveVieja]?.removeAt(index);
          if (_tareas[claveVieja]?.isEmpty ?? false) {
            _tareas.remove(claveVieja);
          }
          _tareas.putIfAbsent(claveNueva, () => []);
          _tareas[claveNueva]!.add(tarea);
        });
      }

      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update({'fecha': claveNueva});
      }

      await _localStorage.saveTarea(tarea);
    } catch (e) {
      debugPrint('Error moviendo: $e');
      _mostrarError('Error al mover: ${e.toString()}');
    }
  }

  Future<void> _actualizarTarea(Tarea tarea, String clave, int index) async {
    try {
      if (mounted) {
        setState(() {
          _tareas[clave]?[index] = tarea;
        });
      }

      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update(tareaToFirestoreMap(tarea, clave));
      }

      await _localStorage.saveTarea(tarea);
    } catch (e) {
      debugPrint('Error actualizando: $e');
      _mostrarError('Error al actualizar: ${e.toString()}');
    }
  }

  Future<void> _eliminarTarea(int index, String clave) async {
    try {
      if (clave.isEmpty || !_tareas.containsKey(clave)) return;

      final listaTareas = _tareas[clave]!;
      if (index < 0 || index >= listaTareas.length) return;

      final confirmado =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: const Text('¿Eliminar esta tarea?'),
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

      if (!confirmado) return;

      final tarea = listaTareas[index];

      if (mounted) {
        setState(() {
          listaTareas.removeAt(index);
          if (listaTareas.isEmpty) _tareas.remove(clave);
        });
      }

      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .delete();
      }

      await _localStorage.deleteTarea(tarea.id);
    } catch (e) {
      debugPrint('Error eliminando: $e');
      _mostrarError('Error al eliminar: ${e.toString()}');
    }
  }

  // =============== DIÁLOGOS Y EDICIÓN ===============
  void editarTarea(int index, List<Tarea> lista, String claveActual) async {
    final tareaActual = lista[index];
    final horaActual = _obtenerHoraDeTarea(tareaActual);
    final fechaActual = dateFromTaskKey(claveActual);

    final result = await mostrarDialogoEditarTarea(
      context: context,
      tarea: tareaActual,
      coloresDisponibles: coloresDisponibles,
      horaActual: horaActual,
      fechaActual: fechaActual,
    );

    if (result != null) {
      final tareaEditada = result['tarea'] as Tarea;
      final nuevaHora = result['hora'] as int;
      final nuevaFecha = result['fecha'] as DateTime;
      final nuevaClave = getTaskKey(nuevaFecha, nuevaHora);

      if (nuevaClave == claveActual) {
        await _actualizarTarea(tareaEditada, claveActual, index);
      } else {
        await _moverTarea(tareaEditada, claveActual, nuevaClave, index);
      }
    }
  }

  // =============== HELPERS Y UTILIDADES ===============
  String _obtenerHoraDeTarea(Tarea tarea) {
    try {
      final entrada = _tareas.entries.firstWhere(
        (entry) => entry.value.contains(tarea),
      );
      return hourFromTaskKey(entrada.key);
    } catch (_) {
      return '00';
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _addTareas() {
    showAddTaskDialog(
      context: context,
      onSave: (tarea, clave) => _guardarTarea(tarea),
      initialDate: DateTime.now(),
      availableColors: coloresDisponibles,
    );
  }

  void _buscarTareas() {
    showSearch(
      context: context,
      delegate: TareaSearchDelegate(tareas: _tareas),
    );
  }

  // =============== UI - BUILD ===============
  @override
  Widget build(BuildContext context) {
    final tareasDelDia = _tareas.values.expand((i) => i).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Tareas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : tareasDelDia.isEmpty
              ? const Center(
                child: Text(
                  'No hay Tareas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: tareasDelDia.length,
                itemBuilder: (context, index) {
                  final tarea = tareasDelDia[index];
                  final entrada = _tareas.entries.firstWhere(
                    (entry) => entry.value.contains(tarea),
                  );
                  final claveCorrecta = entrada.key;
                  final expandida = _tareasExpandida.contains(tarea);

                  return Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap:
                          () => setState(() {
                            if (expandida) {
                              _tareasExpandida.remove(tarea);
                            } else {
                              _tareasExpandida.add(tarea);
                            }
                          }),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: tarea.completada,
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          _marcarCompletada(tarea, value);
                                        }
                                      },
                                      activeColor: tarea.color,
                                    ),
                                    CircleAvatar(
                                      backgroundColor: tarea.color,
                                      child: const Icon(
                                        Icons.menu_book,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tarea.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration:
                                                tarea.completada
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                            color:
                                                tarea.completada
                                                    ? Colors.grey
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.color,
                                          ),
                                        ),
                                        Text(
                                          'Fecha: ${formatearFecha(tarea.fechaCreacion)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  expandida
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                              ],
                            ),
                            if (expandida) ...[
                              const SizedBox(height: 8),
                              Text("Descripción: ${tarea.descripcion}"),
                              Text("Materia: ${tarea.materia}"),
                              Text("Profesor: ${tarea.profesor}"),
                              Text("Créditos: ${tarea.creditos}"),
                              Text("NRC: ${tarea.nrc}"),
                              Text("Hora: ${_obtenerHoraDeTarea(tarea)}:00"),
                              Text(
                                'Prioridad: ${tarea.prioridad}',
                                style: TextStyle(
                                  color: getPrioridadColor(tarea.prioridad),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tarea.completada)
                                Text(
                                  "Completada el: ${DateFormat('dd/MM/yyyy').format(tarea.fechaCreacion)}",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      () => editarTarea(
                                        index,
                                        _tareas[claveCorrecta]!,
                                        claveCorrecta,
                                      ),
                                  child: const Text('Editar'),
                                ),
                                TextButton(
                                  onPressed:
                                      () =>
                                          _eliminarTarea(index, claveCorrecta),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: CustomBottomNavBar(
        parentContext: context,
        onAdd: _addTareas,
        onSearch: _buscarTareas,
        coloresDisponibles: coloresDisponibles,
      ),
    );
  }
}
