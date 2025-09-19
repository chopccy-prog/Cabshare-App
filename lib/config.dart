// lib/config.dart - Updated to use new Env configuration
import 'env.dart';

class Config {
  // DEPRECATED: Use Env.apiBase instead
  @deprecated
  static const String baseUrl = 'http://192.168.1.7:5000';
  
  // UPDATED: Use the new Env configuration
  static String get apiBaseUrl => Env.apiBase;
  
  // Backward compatibility
  static String get defaultApiUrl => Env.apiBase;
}

// App configuration class
class AppConfig {
  // UPDATED: Use the new Env configuration
  static String get baseUrl => Env.apiBase;
}
