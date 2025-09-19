// lib/env.dart - Complete Environment Configuration
class Env {
  // API Configuration (from dart-define)
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator default
  );

  // Supabase Configuration (from dart-define)
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Environment helpers
  static const bool isProduction = String.fromEnvironment('FLUTTER_ENV') == 'production';
  static const bool isDevelopment = !isProduction;

  // API endpoints
  static String get authEndpoint => '$apiBase/api/auth';
  static String get ridesEndpoint => '$apiBase/api/rides';
  static String get bookingsEndpoint => '$apiBase/api/bookings';
  static String get walletEndpoint => '$apiBase/api/wallet';

  // Validation
  static bool get isConfigured {
    return apiBase.isNotEmpty && 
           supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty;
  }

  // Debug info
  static Map<String, String> get debugInfo => {
    'API_BASE': apiBase,
    'SUPABASE_URL': supabaseUrl.isNotEmpty ? '${supabaseUrl.substring(0, 20)}...' : 'NOT_SET',
    'SUPABASE_ANON_KEY': supabaseAnonKey.isNotEmpty ? '${supabaseAnonKey.substring(0, 20)}...' : 'NOT_SET',
    'IS_CONFIGURED': isConfigured.toString(),
  };
}
