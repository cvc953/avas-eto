import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/services/local_database.dart';
import 'package:avas_eto/services/local_storage_service.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:avas_eto/utils/tareas_location_helper.dart';
import '../dialogs/agregar_tarea.dart';
import 'package:flutter/material.dart';
import 'package:avas_eto/screens/more_options.dart';
import 'package:avas_eto/screens/eisenhower_screen.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/eisenhower_matrix.dart';
import '../widgets/buscar_tareas.dart';
import '../utils/task_key_generator.dart';
import 'tareas_tab_view.dart';

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

  // loading state not currently used by the UI
  bool _isOnline = true;
  String _tipoOrdenamiento = 'reciente';
  int _selectedIndex = 1; // 0: Matriz, 1: Tareas, 2: Más

  late final LocalStorageService _localStorage;
  late final ConectividadService _conectividadService;
  late final TareasRepository _repo;
  late final TareasController _controller;
  final LocalDatabase _localDb = LocalDatabase();

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
      _controller = TareasController(
        _repo,
        _localStorage,
        _conectividadService,
      );

      _conectividadService.setupListener((isOnline) {
        setState(() => _isOnline = isOnline);
      });

      await _controller.init();
      _controller.ordenar(_tipoOrdenamiento);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error inicializando: $e');
      if (mounted) setState(() {});
    }
  }

  void _ordenarTareas() {
    _controller.ordenar(_tipoOrdenamiento);
  }

  Future<void> _guardarTarea(Tarea tarea) async {
    final clave = TaskKeyGenerator.generateKeyFromDateTime(
      tarea.fechaVencimiento,
    );

    await _controller.guardar(tarea, clave, _isOnline);
    if (mounted) setState(() => _ordenarTareas());
  }

  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    await _controller.marcarCompletada(tarea, completada, _isOnline);
    if (mounted) setState(() => _ordenarTareas());
  }

  Future<void> _moverTarea(
    Tarea tarea,
    String claveVieja,
    String claveNueva,
    int index,
  ) async {
    try {
      await _controller.moverTarea(tarea, claveVieja, claveNueva);
      if (mounted) setState(() => _ordenarTareas());
    } catch (e) {
      debugPrint('Error moviendo: $e');
      _mostrarError('Error al mover: ${e.toString()}');
    }
  }

  Future<void> _actualizarTarea(Tarea tarea, String clave, int index) async {
    try {
      await _controller.actualizar(tarea, clave);
      if (mounted) setState(() => _ordenarTareas());
    } catch (e) {
      debugPrint('Error actualizando: $e');
      _mostrarError('Error al actualizar: ${e.toString()}');
    }
  }

  Future<void> _eliminarTarea(int index, String clave) async {
    try {
      final mapa = _controller.tareas;
      if (clave.isEmpty || !mapa.containsKey(clave)) return;
      final listaTareas = mapa[clave]!;
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
      await _controller.eliminar(tarea, _isOnline);
      if (mounted) setState(() => _ordenarTareas());
    } catch (e) {
      debugPrint('Error eliminando: $e');
      _mostrarError('Error al eliminar: ${e.toString()}');
    }
  }

  void editarTarea(int index, List<Tarea> lista, String claveActual) async {
    final tareaActual = lista[index];

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EditTaskDialog(
            tarea: tareaActual,
            onSave: (tareaEditada, clave) {
              Navigator.pop(context, {'tarea': tareaEditada, 'clave': clave});
            },
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
    );
  }

  void _buscarTareas() {
    showSearch(
      context: context,
      delegate: TareaSearchDelegate(tareas: _controller.tareas),
    );
  }

  void _onEliminarTarea(Tarea tarea) {
    final ubicacion = buscarUbicacionTarea(_controller.tareas, tarea);
    _eliminarTarea(ubicacion.value, ubicacion.key);
  }

  void _onEditarTarea(Tarea tarea) async {
    final ubicacion = buscarUbicacionTarea(_controller.tareas, tarea);
    final claveActual = ubicacion.key;
    final index = ubicacion.value;

    editarTarea(index, _controller.tareas[claveActual]!, claveActual);
  }

  void _toggleExpandida(Tarea tarea) {
    setState(() {
      _controller.toggleExpandida(tarea);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = <String>['Pendientes', 'Completadas'];

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
                  title: const Text(
                    'Tareas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      menuPadding: const EdgeInsets.all(10),
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
                      child: const Padding(
                        padding: EdgeInsets.all(10),
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

          body: _buildBody(),
        ),
        floatingActionButton:
            _selectedIndex == 1
                ? FloatingActionButton(
                  onPressed: _addTareas,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add),
                )
                : null,
        bottomNavigationBar: CustomBottomNavBar(
          parentContext: context,
          currentIndex: _selectedIndex,
          onSelect: (i) {
            if (i == 2) {
              // Más -> push MoreOptions
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoreOptions()),
              );
              return;
            }
            if (i == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EisenhowerScreen(
                        controller: _controller,
                        onAddTask: (t) async => await _guardarTarea(t),
                      ),
                ),
              );
              return;
            }

            setState(() => _selectedIndex = i);
          },
          coloresDisponibles: coloresDisponibles,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return EisenhowerMatrix(
        tareas: _controller.tareas.values.expand((e) => e).toList(),
      );
    }

    // default: tareas view
    return TareasTabsView(
      controller: _controller,
      onToggle: _toggleExpandida,
      onCheck: _marcarCompletada,
      onEditar: _onEditarTarea,
      onEliminar: _onEliminarTarea,
    );
  }
}
