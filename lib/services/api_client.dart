// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  // For real device on same Wi-Fi, replace with your machine LAN IP, e.g. http://192.168.1.10:3000
  static const String _fallbackBase = String.fromEnvironment(
    'CABSHARE_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final String baseUrl;
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _fallbackBase;

  Future<Map<String, String>> _defaultHeaders() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
    // If you are NOT using Supabase auth in the app, remove Authorization.
  }

  // -------- Rides --------

  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? when, // yyyy-MM-dd
  }) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from_location'] = from;
    if (to != null && to.isNotEmpty)     qp['to_location']   = to;
    if (when != null && when.isNotEmpty) qp['depart_date']   = when;

    final url = Uri.parse('$baseUrl/rides').replace(queryParameters: qp);
    final res = await http.get(url, headers: await _defaultHeaders());

    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) return decoded;
    throw Exception('Unexpected response (expected list)');
  }

  Future<Map<String, dynamic>> getRide(String rideId) async {
    final url = Uri.parse('$baseUrl/rides/$rideId');
    final res = await http.get(url, headers: await _defaultHeaders());
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response (expected object)');
  }

  Future<void> requestBooking(String rideId, int seats) async {
    final url = Uri.parse('$baseUrl/rides/$rideId/book');
    final res = await http.post(
      url,
      headers: await _defaultHeaders(),
      body: json.encode({'seats': seats}),
    );
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departDate, // yyyy-MM-dd
    String? departTime,         // HH:mm or HH:mm:ss
    required int seatsTotal,
    required int pricePerSeatInr,
    required String rideType, // private | shared | commercial_full
  }) async {
    final url = Uri.parse('$baseUrl/rides');
    final body = {
      'from_location': fromLocation,
      'to_location': toLocation,
      'depart_date': departDate,
      if (departTime != null && departTime.isNotEmpty) 'depart_time': departTime,
      'seats_total': seatsTotal,
      'price_per_seat_inr': pricePerSeatInr,
      'ride_type': rideType,
    };

    final res = await http.post(
      url,
      headers: await _defaultHeaders(),
      body: json.encode(body),
    );

    if (res.statusCode != 201) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// Returns { published: [], booked: [] }
  Future<Map<String, dynamic>> myRides() async {
    final url = Uri.parse('$baseUrl/rides/me/list');
    final res = await http.get(url, headers: await _defaultHeaders());
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response (expected object)');
  }

  // -------- Inbox (optional placeholder to avoid 404s) --------

  Future<List<dynamic>> inbox() async {
    // If you don’t have messages yet, return empty for now
    return <dynamic>[];
  }
}
