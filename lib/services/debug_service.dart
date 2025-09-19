// lib/services/debug_service.dart - Debug Service for Testing Backend Connection
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';

class DebugService {
  static Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      print('Testing backend connection to: ${Env.apiBase}');
      
      // Test health endpoint
      final response = await http.get(
        Uri.parse('${Env.apiBase}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Health check response: ${response.statusCode}');
      print('Health check body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'response': response.body,
        'api_base': Env.apiBase,
      };
    } catch (e) {
      print('Backend connection test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'api_base': Env.apiBase,
      };
    }
  }

  static Future<Map<String, dynamic>> testRegistrationEndpoint({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      print('Testing registration endpoint...');
      print('API Base: ${Env.apiBase}');
      print('Registration URL: ${Env.apiBase}/api/auth/register');
      
      final payload = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      };
      
      print('Registration payload: ${jsonEncode(payload)}');
      
      final response = await http.post(
        Uri.parse('${Env.apiBase}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'status_code': response.statusCode,
        'response': response.body,
        'url': '${Env.apiBase}/api/auth/register',
      };
    } catch (e) {
      print('Registration endpoint test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'url': '${Env.apiBase}/api/auth/register',
      };
    }
  }
}
