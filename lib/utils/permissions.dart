import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> Requestnotifications() async {
    final notificantion = await Permission.notification.request();
    return notificantion.isGranted;
  }
}
