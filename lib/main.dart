import 'dart:io' show Platform;
import 'package:avas_eto/screens/tareas.dart';
import 'package:avas_eto/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:avas_eto/controller/auth_controller.dart';
import 'package:avas_eto/controller/settings_controller.dart';
import 'package:avas_eto/controller/tareas_controller.dart';
import 'package:avas_eto/services/conectividad_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/local_database.dart';
import 'services/local_storage_service.dart';
import 'services/tarea_repository.dart';
import 'package:avas_eto/repositories/tareas_repository.dart';
import 'package:avas_eto/utils/permissions.dart';
import 'package:avas_eto/services/upload_queue_service.dart';
import 'package:avas_eto/services/drive_upload_orchestrator.dart';
import 'package:avas_eto/services/background_upload_scheduler.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Notificación en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for DateFormat(..., 'es') used in schedule sheets.
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

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

  await BackgroundUploadScheduler.initialize();

  // Inicializar servicio de notificaciones (Awesome Notifications)
  // Esto prepara canales y permisos dentro del servicio
  NotificationService();

  // 2. Inicialización de la base de datos local
  final localDb = LocalDatabase();
  final localStorage = LocalStorageService(localDb);
  final uploadQueueService = UploadQueueService(localDb);
  final conectividadService = ConectividadService();

  // 3. Creación del repositorio (corregido)
  final tareaRepository = TareaRepository(
    firebaseSupported && firebaseApp != null
        ? FirebaseFirestore.instance
        : null,
    localStorage,
  );

  // Wrapper providing the legacy API expected by controllers
  final driveUploadOrchestrator = DriveUploadOrchestrator(
    uploadQueueService,
    localStorage,
    conectividadService,
    NotificationService(),
    firebaseSupported && firebaseApp != null
        ? FirebaseFirestore.instance
        : null,
  );
  final tareasRepository = TareasRepository(
    localStorage,
    uploadQueueService,
    driveUploadOrchestrator,
  );

  // Controllers to provide via Provider
  final authController = AuthController();
  final settingsController = SettingsController();
  await settingsController.init(); // Inicializar para cargar preferencias
  final tareasController = TareasController(
    tareasRepository,
    localStorage,
    conectividadService,
  );
  await tareasController.init();
  await driveUploadOrchestrator.processPendingUploads();
  await BackgroundUploadScheduler.ensureScheduled();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authController),
        ChangeNotifierProvider.value(value: settingsController),
        Provider.value(value: tareasController),
      ],
      child: MyApp(
        firebaseEnabled: firebaseSupported && firebaseApp != null,
        tareaRepository: tareaRepository,
      ),
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
    final settingsController = Provider.of<SettingsController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsController.themeMode,
      home:
          firebaseEnabled
              ? Tareas(tareaRepository: tareaRepository)
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
