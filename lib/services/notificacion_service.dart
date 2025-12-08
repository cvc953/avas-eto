import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Inicializa las notificaciones locales
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// Configura escucha de mensajes en primer plano
void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_tareas',
            'Tareas',
            channelDescription: 'Canal para notificaciones de tareas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

/// Solicita permisos para notificaciones
Future<void> requestNotificationPermission() async {
  await FirebaseMessaging.instance.requestPermission();
}
