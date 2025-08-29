// lib/core/config_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  ConfigService._();
  static final ConfigService instance = ConfigService._();

  static const _keyBaseUrl = 'base_url';

  /// Default to your current LAN IP
  String _baseUrl = 'http://192.168.1.35:5000';
  String get baseUrl => _baseUrl;

  /// Call once at app start (before ApiClient is used)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? _baseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = url;
    await prefs.setString(_keyBaseUrl, url);
  }
}
