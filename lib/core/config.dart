import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _kBaseUrlKey = 'base_url';

  // <-- UPDATE THIS WHEN YOUR LAN IP CHANGES
  static const String defaultBaseUrl = 'http://192.168.1.35:5000';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBaseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrlKey, url);
  }
}
