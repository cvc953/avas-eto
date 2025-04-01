import 'package:flutter/material.dart';

class Botoninicio extends StatelessWidget {
  final Function()? onTap;

  const Botoninicio({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: EdgeInsets.symmetric(horizontal: 70),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
