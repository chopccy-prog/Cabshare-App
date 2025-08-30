import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const _kBaseUrlKey = 'base_url';
  // Default to your current LAN IP + port (you can change this from the UI).
  static const String _fallbackBaseUrl = 'http://192.168.1.35:5000';

  String _baseUrl = _fallbackBaseUrl;
  String get baseUrl => _baseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kBaseUrlKey) ?? _fallbackBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrlKey, value);
  }
}
