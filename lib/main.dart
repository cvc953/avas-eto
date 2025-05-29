import 'dart:io' show Platform;
import 'package:ap/screens/tareas.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/local_database.dart';
import 'services/local_storage_service.dart';
import 'services/tarea_repository.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Notificación en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización de Firebase
  final bool firebaseSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;
  FirebaseApp? firebaseApp;

  if (firebaseSupported) {
    try {
      firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Configuración de notificaciones
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: androidSettings),
      );
    } catch (e) {
      print('Error inicializando Firebase: $e');
    }
  }

  // 2. Inicialización de la base de datos local
  final localDb = LocalDatabase();
  final localStorage = LocalStorageService(localDb);

  // 3. Creación del repositorio (corregido)
  final tareaRepository = TareaRepository(
    firebaseSupported && firebaseApp != null
        ? FirebaseFirestore.instance
        : null,
    localStorage,
  );

  runApp(
    MyApp(
      firebaseEnabled: firebaseSupported && firebaseApp != null,
      tareaRepository: tareaRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;
  final TareaRepository tareaRepository;

  const MyApp({
    super.key,
    required this.firebaseEnabled,
    required this.tareaRepository, // Corregido
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home:
          firebaseEnabled
              ? Tareas(tareaRepository: tareaRepository) // Corregido
              : Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Firebase no es compatible en esta plataforma',
                        style: TextStyle(fontSize: 18),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => Tareas(
                                      tareaRepository: tareaRepository,
                                    ),
                              ),
                            ),
                        child: const Text('Usar modo local solamente'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

/*import 'dart:io' show Platform;
import 'package:ap/screens/tareas.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'services/local_database.dart';
import 'services/local_storage_service.dart';

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

  final localDb = LocalDatabase();
  await localDb.init();

  final localStorage = LocalStorageService(localDb);

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
