import 'package:flutter/material.dart';

class Tareas extends StatelessWidget {
  const Tareas({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          //color: Colors.blue[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(children: []),
      ),
    );
  }
}
