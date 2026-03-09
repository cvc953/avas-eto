import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:provider/provider.dart';
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
// moved key generation to controller
import 'tareas_tab_view.dart';

class TareasInicio extends StatefulWidget {
  const TareasInicio({super.key});

  @override
  _TareasInicioState createState() => _TareasInicioState();
}

class _TareasInicioState extends State<TareasInicio> {
  // loading state not currently used by the UI
  bool _isOnline = true;
  String _tipoOrdenamiento = 'reciente';
  int _selectedIndex = 1; // 0: Matriz, 1: Tareas, 2: Más
  late final TareasController _controller;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Try to obtain a provided controller first; otherwise create one.
      try {
        _controller = Provider.of<TareasController>(context, listen: false);
      } catch (_) {
        _controller = await TareasController.create();
      }

      _controller.setupConnectivityListener((isOnline) {
        setState(() => _isOnline = isOnline);
      });

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
    await _controller.guardar(tarea, _isOnline);
    if (mounted) setState(() => _ordenarTareas());
  }

  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    // Optimistic update: update UI immediately, then sync in background.
    _controller.markCompletadaLocal(tarea, completada);
    if (mounted) setState(() {});

    try {
      await _controller.marcarCompletada(tarea, completada, _isOnline);
    } catch (e) {
      debugPrint('Error sincronizando marca completada: $e');
      // Optionally show error to user
      if (mounted) _mostrarError('No se pudo sincronizar el cambio');
    }
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
            onDelete: () {
              Navigator.pop(context, {'delete': true});
            },
          ),
    );

    if (result != null) {
      await _controller.processEditResult(
        result,
        claveActual,
        index,
        _isOnline,
      );
      if (mounted) setState(() => _ordenarTareas());
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

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = <String>['Pendientes', 'Completadas'];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, InnerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Tareas',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
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
          currentIndex: _selectedIndex,
          onSelect: (i) {
            if (i == 2) {
              // Más -> push MoreOptions
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MoreOptions(
                        onAddTask: (t) async => await _guardarTarea(t),
                        onToggle: (t, c) async => await _marcarCompletada(t, c),
                      ),
                ),
              );
              return;
            }
            if (i == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EisenhowerScreen(
                        onAddTask: (t) async => await _guardarTarea(t),
                        onToggle:
                            (tarea, completada) async =>
                                await _marcarCompletada(tarea, completada),
                        currentIndex: 0,
                      ),
                ),
              );
              return;
            }

            setState(() => _selectedIndex = i);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return EisenhowerMatrix(
        tareas: _controller.tareas.values.expand((e) => e).toList(),
        onToggle:
            (tarea, completada) async =>
                await _marcarCompletada(tarea, completada),
      );
    }

    // default: tareas view
    return TareasTabsView(
      onCheck: _marcarCompletada,
      onEditar: _onEditarTarea,
      onEliminar: _onEliminarTarea,
    );
  }
}
