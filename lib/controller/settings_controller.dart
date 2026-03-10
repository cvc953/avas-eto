import 'package:avas_eto/services/notifications_settings.dart';
import 'package:avas_eto/services/background_upload_scheduler.dart';
import 'package:avas_eto/services/upload_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Controlador para la configuración de la aplicación (notificaciones, tema, etc.).
class SettingsController extends ChangeNotifier {
  static const String _themeKey = "theme_mode";

  ThemeMode _themeMode = ThemeMode.system;
  bool _mobileDataUploadsEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get mobileDataUploadsEnabled => _mobileDataUploadsEnabled;

  /// Inicializa el controlador cargando las preferencias guardadas
  Future<void> init() async {
    await _loadThemeMode();
    await _loadMobileDataUploadsPreference();
  }

  /// Carga el modo de tema guardado
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'system';
    _themeMode = _themeModeFromString(themeString);
    notifyListeners();
  }

  Future<void> _loadMobileDataUploadsPreference() async {
    _mobileDataUploadsEnabled =
        await UploadPreferencesService.isMobileDataUploadEnabled();
    notifyListeners();
  }

  /// Establece el modo de tema
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(mode));
    notifyListeners();
  }

  /// Convierte ThemeMode a String para guardar
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convierte String a ThemeMode al cargar
  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Métodos para notificaciones (existentes)
  Future<bool> isEnabled() async {
    return await NotificationSettings.isEnabled();
  }

  Future<void> setEnabled(bool value) async {
    await NotificationSettings.setEnabled(value);
  }

  Future<void> setMobileDataUploadsEnabled(bool value) async {
    if (_mobileDataUploadsEnabled == value) return;
    _mobileDataUploadsEnabled = value;
    await UploadPreferencesService.setMobileDataUploadEnabled(value);
    await BackgroundUploadScheduler.ensureScheduled();
    notifyListeners();
  }
}
