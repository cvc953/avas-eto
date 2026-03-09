import 'dart:io' show Platform;
import 'package:avas_eto/screens/tareas.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/local_database.dart';
import 'services/local_storage_service.dart';
import 'services/tarea_repository.dart';
import 'package:avas_eto/utils/permissions.dart';

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
    } catch (e) {
      print('Error inicializando Firebase: $e');
    }
  }

  AppPermissions.Requestnotifications();

  // Inicializar servicio de notificaciones (Awesome Notifications)
  // Esto prepara canales y permisos dentro del servicio
  NotificationService();

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
      themeService: ThemeService.instance,
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool firebaseEnabled;
  final TareaRepository tareaRepository;
  final ThemeService themeService;

  const MyApp({
    super.key,
    required this.firebaseEnabled,
    required this.tareaRepository,
    required this.themeService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeService.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home:
          widget.firebaseEnabled
              ? Tareas(tareaRepository: widget.tareaRepository)
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
                                      tareaRepository: widget.tareaRepository,
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
