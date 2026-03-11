import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/utils/task_key_generator.dart';
import '../dialogs/agregar_tarea.dart';
import 'package:flutter/material.dart';
import 'package:avas_eto/screens/more_options.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/eisenhower_matrix.dart';
import '../utils/app_toast.dart';
import 'tareas_tab_view.dart';
import 'quadrant_detail_screen.dart';

class TareasInicio extends StatefulWidget {
  const TareasInicio({super.key});

  @override
  State<TareasInicio> createState() => _TareasInicioState();
}

class _TareasInicioState extends State<TareasInicio> {
  bool _isOnline = true;
  String _tipoOrdenamiento = 'reciente';
  int _selectedIndex = 0; // 0: Tareas, 1: Matriz, 2: Más
  TareasController? _controller;
  bool _isInitialized = false;
  DateTime? _lastBackPressedAt;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 1)) {
      _lastBackPressedAt = now;
      AppToast.info(
        context,
        'Presiona nuevamente para salir',
        duration: const Duration(seconds: 1),
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      try {
        _controller = Provider.of<TareasController>(context, listen: false);
      } catch (_) {
        _controller = await TareasController.create();
      }

      _controller!.setupConnectivityListener((isOnline) {
        if (mounted) setState(() => _isOnline = isOnline);
      });

      await _controller!.init();

      _controller!.ordenar(_tipoOrdenamiento);

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error inicializando: $e');
      if (mounted) setState(() => _isInitialized = false);
    }
  }

  void _ordenarTareas() {
    _controller?.ordenar(_tipoOrdenamiento);
  }

  Future<void> _guardarTarea(Tarea tarea) async {
    if (_controller == null) return;
    await _controller!.guardar(tarea, _isOnline);
    if (mounted) setState(() => _ordenarTareas());
  }

  Future<void> _marcarCompletada(Tarea tarea, bool completada) async {
    if (_controller == null) return;
    _controller!.markCompletadaLocal(tarea, completada);
    if (mounted) setState(() {});

    try {
      await _controller!.marcarCompletada(tarea, completada, _isOnline);
    } catch (e) {
      debugPrint('Error sincronizando marca completada: $e');
      if (mounted) _mostrarError('No se pudo sincronizar el cambio');
    }
    if (mounted) setState(() => _ordenarTareas());
  }

  Future<void> editarTarea(Tarea tarea) async {
    if (!mounted || _controller == null) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EditTaskDialog(
            tarea: tarea,
            onSave: (tareaEditada, clave) {
              Navigator.pop(context, {'tarea': tareaEditada, 'clave': clave});
            },
            onDelete: () {
              Navigator.pop(context, {'delete': true});
            },
          ),
    );

    if (result != null && mounted) {
      try {
        if (result['delete'] == true) {
          _removeTaskOptimistic(tarea);
          if (mounted) setState(() => _ordenarTareas());
          await _controller!.eliminar(tarea, _isOnline);
        } else {
          final tareaEditada = result['tarea'] as Tarea;
          final nuevaClave = result['clave'] as String;
          final claveVieja = TaskKeyGenerator.generateKeyFromDateTime(
            tarea.fechaVencimiento,
          );

          // Detectar cambio de fecha límite y aumentar contador de postergaciones
          final fechaCambio =
              tarea.fechaVencimiento != tareaEditada.fechaVencimiento;
          final tareaConContador =
              fechaCambio
                  ? tareaEditada.copyWith(
                    vecesPospuesta: tareaEditada.vecesPospuesta + 1,
                  )
                  : tareaEditada;

          if (nuevaClave == claveVieja) {
            await _controller!.actualizar(tareaConContador, claveVieja);
          } else {
            await _controller!.moverTarea(
              tareaConContador,
              claveVieja,
              nuevaClave,
            );
          }
        }

        if (mounted) setState(() => _ordenarTareas());
      } catch (e) {
        debugPrint('Error procesando edición: $e');
        if (mounted) _mostrarError('Error al procesar: ${e.toString()}');
      }
    }
  }

  void _removeTaskOptimistic(Tarea tarea) {
    final mapa = _controller?.tareas;
    if (mapa == null) return;

    String? claveParaLimpiar;
    for (final entry in mapa.entries) {
      final originalLength = entry.value.length;
      entry.value.removeWhere((t) => t.id == tarea.id);
      if (entry.value.isEmpty && originalLength > 0) {
        claveParaLimpiar = entry.key;
      }
      if (originalLength != entry.value.length) {
        break;
      }
    }

    if (claveParaLimpiar != null) {
      mapa.remove(claveParaLimpiar);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    try {
      AppToast.error(context, mensaje);
    } catch (e) {
      debugPrint('Error mostrando snackbar: $e');
    }
  }

  void _addTareas() {
    showAddTaskDialog(
      context: context,
      onSave: (tarea, clave) => _guardarTarea(tarea),
      initialDate: DateTime.now(),
    );
  }

  void _onEliminarTarea(Tarea tarea) async {
    if (!mounted || _controller == null) return;

    try {
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
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
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

      if (!confirmado || !mounted) return;

      await _controller!.eliminar(tarea, _isOnline);
      if (mounted) setState(() => _ordenarTareas());
    } catch (e) {
      debugPrint('Error eliminando tarea: $e');
      if (mounted) _mostrarError('Error al eliminar: ${e.toString()}');
    }
  }

  void _onEditarTarea(Tarea tarea) async {
    try {
      await editarTarea(tarea);
    } catch (e) {
      debugPrint('Error editando tarea: $e');
      _mostrarError('Error al editar: ${e.toString()}');
    }
  }

  void _onTapQuadrant(String title, Color color, List<Tarea> tasks) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => QuadrantDetailScreen(
              title: title,
              accentColor: color,
              tareas: tasks,
              onToggle: _marcarCompletada,
              onTapTask: _onEditarTarea,
              onDelete: _onEliminarTarea,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton:
              _selectedIndex == 2
                  ? null
                  : FloatingActionButton(
                    onPressed: _addTareas,
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.add),
                  ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_selectedIndex == 1) {
      return AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Matriz de Eisenhower',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      );
    }

    if (_selectedIndex == 2) {
      return AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Más opciones',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      );
    }

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
            child: Icon(Icons.sort),
          ),
        ),
      ],
      bottom: TabBar(
        tabs: const [Tab(text: 'Foco de hoy'), Tab(text: 'Todas')],
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        labelColor: Theme.of(context).textTheme.bodyLarge?.color,
        indicatorColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedIndex == 2) {
      return MoreOptions(
        embedded: true,
        onAddTask: (t) async => await _guardarTarea(t),
        onToggle: (t, c) async => await _marcarCompletada(t, c),
      );
    }

    if (_selectedIndex == 1) {
      return EisenhowerMatrix(
        tareas: _controller!.tareas.values.expand((e) => e).toList(),
        onToggle:
            (tarea, completada) async =>
                await _marcarCompletada(tarea, completada),
        onTapTask: _onEditarTarea,
        onTapQuadrant: _onTapQuadrant,
      );
    }

    return TareasTabsView(
      tareasFoco: _controller!.obtenerFocoHoy(),
      tareasTodas: _controller!.obtenerTodasLasTareas(),
      onCheck: _marcarCompletada,
      onEditar: _onEditarTarea,
      onEliminar: _onEliminarTarea,
    );
  }
}
