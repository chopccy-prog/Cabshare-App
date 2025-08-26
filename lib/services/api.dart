// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Single place to change the server IP/port.
class Api {
  static const String baseUrl = 'http://192.168.1.7:5000';

  static Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

  /// Search rides: /rides?from=..&to=..&date=YYYY-MM-DD
  static Future<List<Map<String, dynamic>>> searchRides({
    required String from,
    required String to,
    required String date,
  }) async {
    final res = await http.get(_u('/rides', {'from': from, 'to': to, 'date': date}));
    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode} ${res.body}');
    }
    final List data = json.decode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Publish a ride: POST /rides
  static Future<Map<String, dynamic>> postRide(Map<String, dynamic> ride) async {
    final res = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ride),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Publish failed: ${res.statusCode} ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// Get all rides (used to render "Your Rides" after we filter by saved IDs).
  static Future<List<Map<String, dynamic>>> getAllRides() async {
    final res = await http.get(_u('/rides'));
    if (res.statusCode != 200) {
      throw Exception('Fetch rides failed: ${res.statusCode} ${res.body}');
    }
    final List data = json.decode(res.body);
    return data.cast<Map<String, dynamic>>();
  }
}
