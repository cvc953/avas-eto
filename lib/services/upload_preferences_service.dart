import 'package:shared_preferences/shared_preferences.dart';

class UploadPreferencesService {
  static const String _mobileDataUploadsKey = 'mobile_data_uploads_enabled';

  static Future<bool> isMobileDataUploadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mobileDataUploadsKey) ?? false;
  }

  static Future<void> setMobileDataUploadEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mobileDataUploadsKey, value);
  }
}
