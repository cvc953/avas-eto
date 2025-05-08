import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../dialogs/editar_tarea.dart';
import '../widgets/bottom_navigation_bar.dart';

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

  final DateTime _selectedDay = DateTime.now();
  Map<String, List<Tarea>> _tareas = {};
  Set<Tarea> _tareasExpandida = {};

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
                        "Fecha: / ${selectedDate.day.toString().padLeft(2, '0')}/ ${selectedDate.month.toString().padLeft(2, '0')}/ ${selectedDate.year}",
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
                      setState(
                        () => _tareas
                            .putIfAbsent(clave, () => [])
                            .add(nuevaTarea),
                      );
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

  void buscarTareas() {
    showSearch(
      context: context,
      delegate: TareaSearchDelegate(tareas: _tareas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Tarea> tareasDelDia = [];
    _tareas.forEach((key, tareas) {
      //if (key.startsWith(
      // '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}-',
      //)) {
      tareasDelDia.addAll(tareas);
      //}
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
      setState(() {
        lista[index] = tareaEditada;
        _tareas[key] = lista;
      });
    }
  }

  void eliminarTarea(int index, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('Deseas eliminar esta tarea?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tareas[key]?.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}

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
