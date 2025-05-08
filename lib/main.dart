/*import 'dart:io';

import 'package:ap/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ap/services/autenticacion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      //home: const Tareas(),
      home: Autenticacion(),
    );
  }
}*/

import 'dart:io' show Platform;
import 'package:ap/screens/tareas.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool firebaseSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;

  if (firebaseSupported) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(MyApp(firebaseEnabled: firebaseSupported));
}

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;
  const MyApp({super.key, required this.firebaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home:
          firebaseEnabled
              ? Tareas() // Tu pantalla principal que usa Firebase
              : Scaffold(
                body: Center(
                  child: Text(
                    'Firebase no es compatible en esta plataforma',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
    );
  }
}
