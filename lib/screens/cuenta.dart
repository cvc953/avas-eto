import 'package:flutter/material.dart';

class Cuentas extends StatefulWidget {
  const Cuentas({super.key});

  @override
  State<Cuentas> createState() => _Cuentas();
}

class _Cuentas extends State<Cuentas> {
  final TextEditingController usuario = TextEditingController();
  final TextEditingController contrasegna = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //final screenSize = MediaQuery.onPressedf(context).size;
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.deepPurpleAccent,
        title: Center(child: Text('Cuentas')),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(50)),
            TextFormField(
              controller: usuario,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                label: Text('usuario'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(20)),
            TextFormField(
              controller: contrasegna,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                label: Text('contraseña'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(20)),
            ElevatedButton(
              onPressed: iniciarsesion,
              child: Text('Iniciar sesión'),
              //aqui debe ir una condicion para el llamado de la funcion
            ),
          ],
        ),
      ),
    );
  }

  void iniciarsesion() {}
}
