import 'package:app/Registro.dart';
import 'package:flutter/material.dart';
import 'package:app/Login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Tareas(),
    );
  }
}

class Addtarea {
  String title;
  Color color;
  Addtarea({required this.title, required this.color});
}

class Tareas extends StatefulWidget {
  @override
  TareasInicio createState() => TareasInicio();
}

class TareasInicio extends State<Tareas> {
  List<Addtarea> Tareas = [];
  final List<Color> ColoresDisponibles = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
  ];
  Color colorSeleccionado = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Tareas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body:
          Tareas.isEmpty
              ? Center(
                child: Text(
                  'No hay Tareas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: Tareas.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      title: Text(Tareas[index].title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tipo de tarea",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      leading: CircleAvatar(
                        backgroundColor: Tareas[index].color,
                        child: IconButton(
                          icon: Icon(Icons.menu_book, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == "Editar") {
                            // Add functionality for "Editar"
                          } else if (value == "Eliminar") {
                            // Add functionality for "Eliminar"
                            eliminarTareas(index);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: "Editar",
                                child: Text("Editar"),
                              ),
                              PopupMenuItem(
                                value: "Eliminar",
                                child: Text("Eliminar"),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: IconButton(
              icon: Icon(Icons.view_list),
              onPressed: () {
                _menu(context);
              },
            ),
            label: "Vistas",
          ),

          BottomNavigationBarItem(
            icon: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                addTareas();
              },
            ),
            label: "Añadir",
          ),
          BottomNavigationBarItem(
            icon: IconButton(icon: Icon(Icons.search), onPressed: () {}),
            label: "Buscar",
          ),

          BottomNavigationBarItem(
            icon: IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => Login()));
              },
            ),
            label: "Cuenta",
          ),
        ],
      ),
    );
  }

  void _menu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.calendar_view_week_rounded),
              title: Text('Calendario'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.code),
              title: Text('Codigo'),
              onTap: () {},
            ),

            ListTile(
              leading: Icon(Icons.view_week),
              title: Text('Semana'),
              onTap: () {},
            ),

            ListTile(
              leading: Icon(Icons.table_view),
              title: Text('Tabla de progreso'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ajustes'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Ayuda'),
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  void addTareas() {
    TextEditingController TareasController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Agregar tarea'),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min, // Evita que el diálogo se desborde
                children: [
                  TextField(
                    controller: TareasController,
                    decoration: InputDecoration(hintText: 'Escribe tu tarea'),
                  ),
                  SizedBox(height: 10),
                  Text('Selecciona un color'),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children:
                        ColoresDisponibles.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                colorSeleccionado = color;
                              });
                            },
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
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (TareasController.text.isNotEmpty) {
                      // Aquí se usa setState principal para actualizar la pantalla
                      setState(() {
                        Tareas.add(
                          Addtarea(
                            title: TareasController.text,
                            color: colorSeleccionado,
                          ),
                        );
                      });
                      Navigator.of(context).pop(); // Cierra el diálogo
                    }
                  },
                  child: Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void eliminarTareas(int index) {
    setState(() {
      Tareas.removeAt(index);
    });
  }
}
