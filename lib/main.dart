import 'package:ap/widgets/boton_agregar.dart';
import 'package:flutter/material.dart';
import 'screens/login.dart'; // Pantalla de login movida a screens/
import 'screens/Viscalendario.dart'; // Calendario movido a screens/
import 'screens/Vissemana.dart'; // Vista semanal movida a screens/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Tareas(),
    );
  }
}

class Addtarea {
  String title;
  Color color;
  Addtarea({required this.title, required this.color});
}

class Tareas extends StatefulWidget {
  const Tareas({super.key});

  @override
  TareasInicio createState() => TareasInicio();
}

class TareasInicio extends State<Tareas> {
  List<Addtarea> tareas = [];
  final List<Color> coloresDisponibles = [
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
          tareas.isEmpty
              ? Center(
                child: Text(
                  'No hay Tareas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: tareas.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      title: Text(tareas[index].title),
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
                        backgroundColor: tareas[index].color,
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
                BotonAgregar();
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
              leading: Icon(Icons.calendar_month_rounded),
              title: Text('Calendario'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Viscalendario(),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.view_week),
              title: Text('Semana'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Vissemana()),
                );
              },
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

  void eliminarTareas(int index) {
    setState(() {
      tareas.removeAt(index);
    });
  }
}
