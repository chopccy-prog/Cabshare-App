// lib/core/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'config_service.dart';
import '../models/ride.dart';

class ApiClient {
  final ConfigService _config;
  ApiClient(this._config);

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    return Uri.parse('$base$path').replace(
      queryParameters: q?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<void> healthCheck() async {
    final r = await http.get(_u('/health'));
    if (r.statusCode != 200) {
      throw Exception('Health check failed (${r.statusCode})');
    }
  }

  /// Accepts nullable filters so your UI can pass nulls safely.
  /// Backend: GET /rides?from=&to=&date=YYYY-MM-DD
  Future<List<Ride>> search({
    String? from,
    String? to,
    DateTime? date,
  }) async {
    final q = <String, String>{};
    if (from != null && from.trim().isNotEmpty) q['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) q['to'] = to.trim();
    if (date != null) q['date'] = DateFormat('yyyy-MM-dd').format(date);

    final r = await http.get(_u('/rides', q.isEmpty ? null : q));
    if (r.statusCode != 200) {
      throw Exception('Search failed (${r.statusCode}): ${r.body}');
    }

    final data = jsonDecode(r.body);
    final list = (data is Map && data['rides'] is List)
        ? (data['rides'] as List)
        : (data as List);
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Matches your tab usage: publish(when: ...)
  /// Backend: POST /rides  with JSON body
  Future<Ride> publish({
    required String from,
    required String to,
    required DateTime when,
    required int seats,
    required int price,
    required String driverName,
    String? phone,
    String? car,
  }) async {
    final body = {
      'from': from.trim(),
      'to': to.trim(),
      'when': when.toIso8601String(),
      'seats': seats,
      'price': price,
      'driverName': driverName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (car != null && car.trim().isNotEmpty) 'car': car.trim(),
    };

    final r = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('Publish failed (${r.statusCode}): ${r.body}');
    }

    final data = jsonDecode(r.body);
    final rideJson = (data is Map && data['ride'] is Map)
        ? data['ride'] as Map<String, dynamic>
        : (data as Map<String, dynamic>);
    return Ride.fromJson(rideJson);
  }

  /// Booking path: POST /rides/:id/book
  Future<void> book(String rideId) async {
    final r = await http.post(
      _u('/rides/$rideId/book'),
      headers: {'Content-Type': 'application/json'},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('Book failed (${r.statusCode}): ${r.body}');
    }
  }

  /// My rides (simple filter by driverName if provided)
  Future<List<Ride>> myRides({String? driverName}) async {
    final q = <String, String>{};
    if (driverName != null && driverName.trim().isNotEmpty) {
      q['driverName'] = driverName.trim();
    }
    final r = await http.get(_u('/rides', q.isEmpty ? null : q));
    if (r.statusCode != 200) {
      throw Exception('My rides failed (${r.statusCode}): ${r.body}');
    }
    final data = jsonDecode(r.body);
    final list = (data is Map && data['rides'] is List)
        ? (data['rides'] as List)
        : (data as List);
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }
}
