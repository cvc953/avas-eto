import 'package:avas_eto/services/notifications_settings.dart';

/// Controlador para la configuración de la aplicación (notificaciones, etc.).
class SettingsController {
  Future<bool> isEnabled() async {
    return await NotificationSettings.isEnabled();
  }

  Future<void> setEnabled(bool value) async {
    await NotificationSettings.setEnabled(value);
  }
}
