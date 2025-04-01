import 'package:flutter/material.dart';

class LoginInput extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;

  const LoginInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          //fillColor: Colors.grey.shade200,
          filled: true,
          hintText: hintText,
          //hintStyle: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
