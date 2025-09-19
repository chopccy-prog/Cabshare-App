import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  final String _base = AppConfig.baseUrl;

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(Uri.parse('$_base/health'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Health failed: ${res.statusCode} ${res.body}');
  }

// TODO: add your real endpoints here, e.g. search rides, book ride, etc.
// Future<List<Ride>> search(...) => http.get(Uri.parse('$_base/api/rides?...'));
}
