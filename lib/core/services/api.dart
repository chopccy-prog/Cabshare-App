// lib/core/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  /// IMPORTANT: phone + server must be on same Wi-Fi.
  /// Replace with your LAN IP if different.
  static const String baseUrl = String.fromEnvironment(
    'CABSHARE_BASE_URL',
    defaultValue: 'http://192.168.1.7:5000',
  );

  static Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q?.map((k, v) => MapEntry(k, v?.toString())));

  static Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_u(path, query), headers: {'Content-Type': 'application/json'});
    _throwIfBad(res);
    return res;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    _throwIfBad(res);
    return res;
  }

  static void _throwIfBad(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
