import 'package:avas_eto/screens/login.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  bool states = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.deepPurple,
        //title: Center(child: Text('Tareas')),
      ),
      drawer: Drawer(
        child: Container(
          child: ListView(
            children: [
              DrawerHeader(child: Text('aqui deberia poner un logo')),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('cuentas'),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => Login()));
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Agregar tarea'),
                content: TextField(
                  decoration: InputDecoration(hintText: 'Nombre de la tarea'),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Agregar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),

        //backgroundColor: Colors.deepOrange[300],
        // child: Icon(Icons.add),
      ),
    );
  }

  void nuevatarea() {}
}

class Dialog extends StatefulWidget {
  const Dialog({super.key});

  @override
  State<Dialog> createState() => _DialogState();
}

class _DialogState extends State<Dialog> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      padding: EdgeInsets.all(20),
      child: ElevatedButton(
        child: Text('Agregar tarea'),
        onPressed: () {
          openDialog();
        },
      ),
    ),
  );

  Future openDialog() => showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('Agregar tarea'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Nombre de la tarea'),
          ),
        ),
  );
}
