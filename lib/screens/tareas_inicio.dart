import 'package:ap/services/local_database.dart';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/local_storage_service.dart';

class TareaSearchDelegate extends SearchDelegate {
  final Map<String, List<Tarea>> tareas;

  TareaSearchDelegate({required this.tareas});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final resultados =
        tareas.entries
            .expand((entry) => entry.value)
            .where(
              (tarea) =>
                  tarea.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (resultados.isEmpty) {
      return const Center(
        child: Text(
          'No se ha encontrado ninguna tarea.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      children:
          resultados.map((tarea) {
            return ListTile(
              title: Text(tarea.title),
              leading: CircleAvatar(
                backgroundColor: tarea.color,
                child: const Icon(Icons.menu_book, color: Colors.white),
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final sugerencias =
        tareas.entries
            .expand((entry) => entry.value)
            .where(
              (tarea) =>
                  tarea.title.toLowerCase().startsWith(query.toLowerCase()),
            )
            .toList();

    if (sugerencias.isEmpty) {
      return const Center(
        child: Text(
          'No se ha encontrado ninguna tarea.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      children:
          sugerencias.map((tarea) {
            return ListTile(
              title: Text(tarea.title),
              leading: CircleAvatar(
                backgroundColor: tarea.color,
                child: Icon(Icons.menu_book, color: Colors.white),
              ),
            );
          }).toList(),
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

  final LocalDatabase _localDb = LocalDatabase();

  late final LocalStorageService _localStorage;
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  StreamSubscription<QuerySnapshot>? _tareasSubscription;
  final DateTime _selectedDay = DateTime.now();
  final Map<String, List<Tarea>> _tareas = {};
  final Set<Tarea> _tareasExpandida = {};

  String _getTaskKey(DateTime day, int hour) {
    return '${day.year}-${day.month}-${day.day}-$hour';
  }

  String _obtenerHoraDeTarea(Tarea tarea) {
    try {
      final entrada = _tareas.entries.firstWhere(
        (entry) => entry.value.contains(tarea),
      );
      final partes = entrada.key.split('-');
      return partes.last.padLeft(2, '0');
    } catch (_) {
      return '--';
    }
  }

  Widget _buildPrioridadTexto(String prioridad) {
    Color color;
    switch (prioridad) {
      case 'Alta':
        color = Colors.red;
        break;
      case 'Media':
        color = Colors.orange;
        break;
      case 'Baja':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Text(
      'Prioridad: $prioridad',
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  @override
  void initState() {
    super.initState();
    _localStorage = LocalStorageService(_localDb);
    _checkConnectivity();
    _setupConnectivityListener();
    _loadLocalTasks();

    // Configuración de notificaciones
    FirebaseMessaging.instance.requestPermission();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_tareas',
              'Tareas',
              channelDescription: 'Canal para notificaciones de tareas',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Inicializar Firebase y escuchar cambios
    Firebase.initializeApp().then((_) {
      _configurarEscuchaTiempoReal();
    });
  }

  void _configurarEscuchaTiempoReal() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _tareasSubscription?.cancel(); // Cancela cualquier suscripción previa

    _tareasSubscription = FirebaseFirestore.instance
        .collection('tareas')
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: false)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          setState(() {
            _tareas.clear();

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final tarea = Tarea(
                id: doc.id, // Asegúrate de incluir el ID del documento
                title: data['titulo'] ?? '',
                descripcion: data['descripcion'] ?? '',
                profesor: data['profesor'] ?? '',
                creditos: data['creditos'] ?? 0,
                nrc: data['nrc'] ?? 0,
                prioridad: data['prioridad'] ?? 'Media',
                color: Color(
                  int.parse(data['color'] ?? '0xFF000000', radix: 16),
                ),
              );

              final clave = data['fecha'] as String;
              _tareas.putIfAbsent(clave, () => []).add(tarea);
            }
          });
        });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      if (_isOnline) {
        _syncLocalTasks();
      }
    });
  }

  Future<void> _loadLocalTasks() async {
    try {
      final localTasks = await _localStorage.getTareas();
      setState(() {
        // Solo añade tareas locales si no están ya en la lista
        for (var task in localTasks) {
          final exists = _tareas.entries.any(
            (entry) => entry.value.any((t) => t.id == task.id),
          );

          if (!exists) {
            final key = 'local_${task.id}';
            _tareas.putIfAbsent(key, () => []).add(task);
          }
        }
      });
    } catch (e) {
      debugPrint('Error cargando tareas locales: $e');
    }
  }

  Future<void> _syncLocalTasks() async {
    try {
      final localTasks = await _localStorage.getTareas();
      for (var task in localTasks) {
        if (task.id.startsWith('local_')) {
          final clave = _getTaskKey(DateTime.now(), TimeOfDay.now().hour);
          await _guardarTareaEnFirestore(task, clave);

          // Actualiza el estado local antes de eliminar
          setState(() {
            _tareas.forEach((key, value) {
              value.removeWhere((t) => t.id == task.id);
            });
          });

          await _localStorage.deleteTarea(task.id);
        }
      }

      // Vuelve a cargar todas las tareas después de sincronizar
      _configurarEscuchaTiempoReal();
    } catch (e) {
      debugPrint('Error sincronizando tareas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sincronizando tareas: ${e.toString()}')),
      );
    }
  }

  Future<void> _guardarTareaEnFirestore(Tarea tarea, String clave) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Creamos una copia de la tarea para mostrar inmediatamente
      final tareaTemporal = tarea.copyWith(
        id:
            tarea.id.startsWith('local_')
                ? 'temp_${DateTime.now().millisecondsSinceEpoch}'
                : tarea.id,
      );

      // Actualizamos el estado local primero
      if (mounted) {
        setState(() {
          _tareas.putIfAbsent(clave, () => []).add(tareaTemporal);
        });
      }

      if (_isOnline) {
        // Guardar en Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('tareas')
            .add({
              'titulo': tarea.title,
              'descripcion': tarea.descripcion,
              'profesor': tarea.profesor,
              'creditos': tarea.creditos,
              'nrc': tarea.nrc,
              'prioridad': tarea.prioridad,
              'color': tarea.color.value.toRadixString(16),
              'fecha': clave,
              'hora': clave.split('-').last,
              'creadoEn': FieldValue.serverTimestamp(),
              'userId': user.uid,
            });

        // Actualizar el estado con el ID real de Firestore
        if (mounted) {
          setState(() {
            // Removemos la temporal
            _tareas[clave]?.removeWhere((t) => t.id == tareaTemporal.id);
            // Añadimos la versión con ID real
            _tareas
                .putIfAbsent(clave, () => [])
                .add(tarea.copyWith(id: docRef.id));
          });
        }

        // Guardar también localmente por si acaso
        await _localStorage.saveTarea(tarea.copyWith(id: docRef.id));
      } else {
        // Solo modo offline - guardar localmente
        await _localStorage.saveTarea(tareaTemporal);
      }
    } catch (e) {
      debugPrint('Error al guardar tarea: $e');
      // Revertir cambios en caso de error
      if (mounted) {
        setState(() {
          _tareas[clave]?.removeWhere((t) => t.id.startsWith('temp_'));
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _tareasSubscription?.cancel();
    super.dispose();
  }

  /* Future<void> _guardarTareaEnFirestore(Tarea tarea, String clave) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await FirebaseFirestore.instance.collection('tareas').doc(clave).set({
        'titulo': tarea.title,
        'descripcion': tarea.descripcion,
        'profesor': tarea.profesor,
        'creditos': tarea.creditos,
        'nrc': tarea.nrc,
        'prioridad': tarea.prioridad,
        'color': tarea.color.value.toRadixString(16),
        'fecha': clave,
        'hora': clave.split('-').last,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user.uid, // Añadir el ID del usuario
      });

      print('Tarea guardada en Firestore');
    } on FirebaseException catch (e) {
      print('Error de Firebase: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.message}')));
    } catch (e) {
      print('Error inesperado: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    }
  }*/

  void addTareas() {
    TextEditingController tareaController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();
    TextEditingController profesorController = TextEditingController();
    TextEditingController creditosController = TextEditingController();
    TextEditingController nrcController = TextEditingController();
    Color colorSeleccionado = coloresDisponibles[0];
    int selectedHour = TimeOfDay.now().hour;
    DateTime selectedDate = _selectedDay;
    String prioridadSeleccionada = 'Media';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nueva Tarea"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tareaController,
                      decoration: const InputDecoration(
                        hintText: "Nombre de la materia",
                      ),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        hintText: "Descripción",
                      ),
                    ),
                    TextField(
                      controller: profesorController,
                      decoration: const InputDecoration(hintText: "Profesor"),
                    ),
                    TextField(
                      maxLength: 1,
                      controller: creditosController,
                      decoration: const InputDecoration(
                        hintText: "Número de créditos",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      maxLength: 4,
                      controller: nrcController,
                      decoration: const InputDecoration(hintText: "NRC"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Text('Seleccione la prioridad de la tarea'),
                    DropdownButton<String>(
                      value: prioridadSeleccionada,
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => prioridadSeleccionada = value);
                        }
                      },
                      items:
                          ['Alta', 'Media', 'Baja']
                              .map(
                                (prioridad) => DropdownMenuItem(
                                  value: prioridad,
                                  child: Text(prioridad),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() => selectedDate = pickedDate);
                        }
                      },
                      child: Text(
                        "Fecha: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                      ),
                    ),
                    DropdownButton<int>(
                      value: selectedHour,
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => selectedHour = value);
                        }
                      },
                      items: List.generate(
                        24,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text("${index.toString().padLeft(2, '0')}:00"),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      children:
                          coloresDisponibles
                              .map(
                                (color) => GestureDetector(
                                  onTap:
                                      () => setStateDialog(
                                        () => colorSeleccionado = color,
                                      ),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border:
                                          colorSeleccionado == color
                                              ? Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    if (tareaController.text.isNotEmpty) {
                      final nuevaTarea = Tarea(
                        title: tareaController.text,
                        descripcion: descripcionController.text,
                        profesor: profesorController.text,
                        creditos: int.tryParse(creditosController.text) ?? 0,
                        nrc: int.tryParse(nrcController.text) ?? 0,
                        prioridad: prioridadSeleccionada,
                        color: colorSeleccionado,
                      );
                      final clave = _getTaskKey(selectedDate, selectedHour);

                      _guardarTareaEnFirestore(nuevaTarea, clave);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Tarea> tareasDelDia = [];
    _tareas.forEach((key, tareas) {
      tareasDelDia.addAll(tareas);
    });

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
          tareasDelDia.isEmpty
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
                                    CircleAvatar(
                                      backgroundColor: tarea.color,
                                      child: const Icon(
                                        Icons.menu_book,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      tarea.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
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
                              Text("Profesor: ${tarea.profesor}"),
                              Text("Créditos: ${tarea.creditos}"),
                              Text("NRC: ${tarea.nrc}"),
                              Text(
                                "Hora de finalización: ${_obtenerHoraDeTarea(tarea)}:00",
                              ),
                              _buildPrioridadTexto(tarea.prioridad),
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
                                      () => eliminarTarea(index, claveCorrecta),
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
        onAdd: addTareas,
        onSearch: buscarTareas,
      ),
    );
  }

  void editarTarea(int index, List<Tarea> lista, String key) async {
    final tareaEditada = await mostrarDialogoEditarTarea(
      context: context,
      tarea: lista[index],
      coloresDisponibles: coloresDisponibles,
    );

    if (tareaEditada != null) {
      await _actualizarTareaEnFirestore(tareaEditada, key, index);
    }
  }

  Future<void> _actualizarTareaEnFirestore(
    Tarea tarea,
    String clave,
    int index,
  ) async {
    try {
      // Actualización optimista - actualizar primero la UI
      if (mounted) {
        setState(() {
          _tareas[clave]?[index] = tarea;
        });
      }

      if (_isOnline) {
        // Actualizar en Firestore
        await FirebaseFirestore.instance
            .collection('tareas')
            .doc(tarea.id)
            .update({
              'titulo': tarea.title,
              'descripcion': tarea.descripcion,
              'profesor': tarea.profesor,
              'creditos': tarea.creditos,
              'nrc': tarea.nrc,
              'prioridad': tarea.prioridad,
              'color': tarea.color.value.toRadixString(16),
              'fecha': clave,
            });

        // Actualizar también en el almacenamiento local
        await _localStorage.saveTarea(tarea);
      } else {
        // Solo modo offline - guardar localmente
        await _localStorage.saveTarea(tarea);
      }
    } catch (e) {
      debugPrint('Error al actualizar tarea: $e');

      // Revertir cambios en caso de error
      if (mounted) {
        setState(() {
          // Aquí necesitarías tener acceso a la tarea original para revertir
          // Podrías guardar la tarea original antes de editar o recuperarla
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
      );
    }
  }

  void buscarTareas() {
    showSearch(
      context: context,
      delegate: TareaSearchDelegate(tareas: _tareas),
    );
  }

  Future<void> eliminarTarea(int index, String key) async {
    // Verificación de montaje y estado
    if (!mounted) return;

    try {
      // 1. Validación exhaustiva de parámetros
      if (key.isEmpty) {
        debugPrint('🔴 Key vacía proporcionada');
        return;
      }

      if (!_tareas.containsKey(key)) {
        debugPrint('🔴 Key no existe: $key');
        return;
      }

      final listaTareas = _tareas[key]!;
      if (listaTareas.isEmpty) {
        debugPrint('🔴 Lista de tareas vacía para key: $key');
        return;
      }

      if (index < 0 || index >= listaTareas.length) {
        debugPrint(
          '🔴 Índice $index inválido para lista de tamaño ${listaTareas.length}',
        );
        return;
      }

      // 2. Confirmación del usuario
      final confirmado = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: const Text(
                '¿Estás seguro de que deseas eliminar esta tarea?',
              ),
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
      );

      if (confirmado != true) return;

      // 3. Obtener referencia a la tarea
      final tarea = listaTareas[index];
      final id = tarea.id;

      if (id.isEmpty) {
        debugPrint('🔴 ID de tarea vacío');
        return;
      }

      // 4. Eliminación optimista (UI primero)
      setState(() {
        // Crear copia de seguridad por si falla
        final tareaBackup = tarea.copyWith();

        try {
          listaTareas.removeAt(index);
          if (listaTareas.isEmpty) _tareas.remove(key);
        } catch (e) {
          // Revertir si falla la eliminación en UI
          listaTareas.insert(index, tareaBackup);
          _tareas.putIfAbsent(key, () => listaTareas);
          rethrow;
        }
      });

      // 5. Eliminar de Firestore (si es online y no es local)
      if (_isOnline && !id.startsWith('local_')) {
        try {
          await FirebaseFirestore.instance
              .collection('tareas')
              .doc(id)
              .delete();
          debugPrint('✅ Tarea eliminada de Firestore: $id');
        } on FirebaseException catch (e) {
          if (e.code != 'not-found') {
            debugPrint('🔴 Error Firestore: ${e.code}');
            throw Exception('Error al eliminar de Firestore: ${e.message}');
          }
          // Si no se encuentra, continuamos igual
        }
      }

      // 6. Eliminar del almacenamiento local
      try {
        await _localStorage.deleteTarea(id);
        debugPrint('🗑️ Tarea eliminada localmente: $id');
      } catch (e) {
        debugPrint('🔴 Error eliminando localmente: $e');
        throw Exception('Error al eliminar localmente');
      }
    } catch (e, stack) {
      debugPrint('🔴 Error crítico al eliminar: $e\n$stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => eliminarTarea(index, key),
            ),
          ),
        );
      }
    }
  }
}
