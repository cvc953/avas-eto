/*import 'dart:io' show Platform;
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
}*/

import 'dart:io' show Platform;
import 'package:ap/screens/tareas.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Configuración de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler para notificaciones en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Aquí puedes hacer algo cuando llega una notificación en segundo plano
  print('Notificación en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool firebaseSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;

  if (firebaseSupported) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inicializar notificaciones locales
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
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
