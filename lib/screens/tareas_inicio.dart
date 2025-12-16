import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/services/local_database.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:avas_eto/utils/tarea_firestore_mapper.dart';
import 'package:avas_eto/utils/tareas_location_helper.dart';
import '../dialogs/agregar_tarea.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/buscar_tareas.dart';
import '../utils/tarea_helpers.dart';
import 'tareas_tab_view.dart';
import '../controller/tareas_controller.dart';

class TareasInicio extends StatefulWidget {
  const TareasInicio({super.key});

  @override
  _TareasInicioState createState() => _TareasInicioState();
}

class _TareasInicioState extends State<TareasInicio> {
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
  String _tipoOrdenamiento = 'reciente'; // 'reciente' o 'prioridad'

  late final LocalStorageService _localStorage;
  late final ConectividadService _conectividadService;
  late final TareasRepository _repo;

  final LocalDatabase _localDb = LocalDatabase();
  final Map<String, List<Tarea>> _tareas = {};
  final Set<Tarea> _tareasExpandida = {};

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
      _repo = TareasRepository(_localStorage);

      _conectividadService.setupListener((isOnline) {
        setState(() => _isOnline = isOnline);
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _setupFirestoreListener();
      } else {
        await _loadLocalTareas();
      }

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

  Future<void> _setupFirestoreListener() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No hay usuario autenticado');
        return;
      }

      FirebaseFirestore.instance
          .collection('tareas')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (!mounted) return;
              setState(() {
                // Limpiar y reconstruir desde Firestore
                _tareas.clear();
                for (var doc in snapshot.docs) {
                  final tarea = tareaFromFirestore(doc);
                  final fecha = doc['fecha'];
                  _tareas.putIfAbsent(fecha, () => []);
                  _tareas[fecha]!.add(tarea);
                }
                // Aplicar ordenamiento después de cargar desde Firestore
                _ordenarTareas();
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

  Future<void> _loadLocalTareas() async {
    try {
      final tareas = await _localStorage.getTareas();
      if (mounted) {
        setState(() {
          for (var tarea in tareas) {
            // Extraer hora y minutos del DateTime de la tarea
            final hora = tarea.fechaVencimiento.hour;
            final minutos = tarea.fechaVencimiento.minute;
            final clave = getTaskKey(tarea.fechaVencimiento, hora, minutos);
            _tareas.putIfAbsent(clave, () => []);
            if (!_tareas[clave]!.any((t) => t.id == tarea.id)) {
              _tareas[clave]!.add(tarea);
            }
          }
          _ordenarTareas();
        });
      }
    } catch (e) {
      debugPrint('Error cargando tareas locales: $e');
    }
  }

  void _ordenarTareas() {
    for (var lista in _tareas.values) {
      if (_tipoOrdenamiento == 'reciente') {
        // Ordenar por fecha de creación (más reciente primero)
        lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      } else if (_tipoOrdenamiento == 'prioridad') {
        // Ordenar por prioridad: Alta > Media > Baja
        final prioridadValor = {'Alta': 3, 'Media': 2, 'Baja': 1};
        lista.sort((a, b) {
          final valA = prioridadValor[a.prioridad] ?? 0;
          final valB = prioridadValor[b.prioridad] ?? 0;
          return valB.compareTo(valA);
        });
      }
    }
  }

  Future<void> _guardarTarea(Tarea tarea) async {
    final clave = getTaskKey(
      tarea.fechaVencimiento,
      tarea.fechaVencimiento.hour,
      tarea.fechaVencimiento.minute,
    );

    // Usa el repositorio para persistir en Firestore (si hay sesión) y en local
    await _repo.guardar(tarea, clave, _isOnline);

    // Enviar notificación según prioridad
    await NotificationService().notifyTaskCreated(tarea);

    // Reordenar después de guardar
    if (mounted) {
      setState(() {
        _ordenarTareas();
      });
    }
  }

  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    setState(() {
      final entry = _tareas.entries.firstWhere((e) => e.value.contains(tarea));
      final index = entry.value.indexOf(tarea);
      entry.value[index] = tarea.copyWith(completada: completada);
      _ordenarTareas();
    });

    await _repo.marcarCompletada(tarea, completada, _isOnline);
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
          _ordenarTareas();
        });
      }

      if (_isOnline) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(tarea.id)
              .update({'fecha': claveNueva});
        }
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
          _ordenarTareas();
        });
      }

      if (_isOnline) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(tarea.id)
              .update(tareaToFirestoreMap(tarea, clave));
        }
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
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
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
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(tarea.id)
              .delete();
        }
      }

      await _localStorage.deleteTarea(tarea.id);
    } catch (e) {
      debugPrint('Error eliminando: $e');
      _mostrarError('Error al eliminar: ${e.toString()}');
    }
  }

  void editarTarea(int index, List<Tarea> lista, String claveActual) async {
    final tareaActual = lista[index];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => EditTaskDialog(
            tarea: tareaActual,
            onSave: (tareaEditada, clave) {
              Navigator.pop(context, {'tarea': tareaEditada, 'clave': clave});
            },
            availableColors: coloresDisponibles,
          ),
    );

    if (result != null) {
      final tareaEditada = result['tarea'] as Tarea;
      final nuevaClave = result['clave'] as String;

      if (nuevaClave == claveActual) {
        await _actualizarTarea(tareaEditada, claveActual, index);
      } else {
        await _moverTarea(tareaEditada, claveActual, nuevaClave, index);
      }
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

  void _onEliminarTarea(Tarea tarea) {
    final ubicacion = buscarUbicacionTarea(_tareas, tarea);

    _eliminarTarea(
      ubicacion.value, // index
      ubicacion.key, // clave
    );
  }

  void _onEditarTarea(Tarea tarea) async {
    final ubicacion = buscarUbicacionTarea(_tareas, tarea);
    final claveActual = ubicacion.key;
    final index = ubicacion.value;

    editarTarea(
      index,
      _tareas[claveActual]!, // lista correcta
      claveActual,
    );
  }

  void _toggleExpandida(Tarea tarea) {
    setState(() {
      if (_tareasExpandida.contains(tarea)) {
        _tareasExpandida.remove(tarea);
      } else {
        _tareasExpandida.add(tarea);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tareasDelDia = _tareas.values.expand((i) => i).toList();
    final List<String> tabs = <String>['Pendientes', 'Completadas'];
    final controller = TareasController(_tareas, _tareasExpandida);

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, InnerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Tareas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      menuPadding: EdgeInsets.all(10),
                      onSelected: (value) {
                        setState(() {
                          _tipoOrdenamiento = value;
                          _ordenarTareas();
                        });
                      },
                      itemBuilder:
                          (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'reciente',
                              child: Text('Más recientes'),
                            ),
                            const PopupMenuItem(
                              value: 'prioridad',
                              child: Text('Por prioridad'),
                            ),
                          ],
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.sort, color: Colors.white),
                      ),
                    ),
                  ],
                  pinned: true,
                  expandedHeight: 100.0,
                  forceElevated: InnerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: tabs.map((String name) => Tab(text: name)).toList(),
                    unselectedLabelColor: Colors.white70,
                    labelColor: Colors.white,
                    indicatorColor: Colors.white,
                  ),
                ),
              ),
            ];
          },

          body: TareasTabsView(
            controller: controller,
            onToggle: _toggleExpandida,
            onCheck: _marcarCompletada,
            onEditar: _onEditarTarea,
            onEliminar: _onEliminarTarea,
          ), //  ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          parentContext: context,
          onAdd: _addTareas,
          onSearch: _buscarTareas,
          coloresDisponibles: coloresDisponibles,
        ),
      ),
    );
  }
}
