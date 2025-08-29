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

  /// SEARCH rides
  /// Expected backend: GET /rides?from=..&to=..&date=YYYY-MM-DD
  Future<List<Ride>> search({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final r = await http.get(_u('/rides', {
      'from': from,
      'to': to,
      'date': dateStr,
    }));

    if (r.statusCode != 200) {
      throw Exception('Search failed (${r.statusCode}): ${r.body}');
    }

    final data = jsonDecode(r.body);
    final list = (data is Map && data['rides'] is List)
        ? (data['rides'] as List)
        : (data as List);
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
    // Your Ride.fromJson should handle id/_id + when/date+time combos.
  }

  /// PUBLISH ride
  /// Expected backend: POST /rides (JSON body)
  /// Body fields we send: from, to, when (ISO), seats (int), price (int),
  /// driverName, phone (optional), car (optional)
  Future<Ride> publish({
    required String from,
    required String to,
    required DateTime date,
    required DateTime timeOfDayLocal, // pass date+time combined (local)
    required int seats,
    required int price,
    required String driverName,
    String? phone,
    String? car,
  }) async {
    // Combine date + time-of-day into one DateTime if caller passed separate parts.
    final whenIso = timeOfDayLocal.toIso8601String();

    final body = {
      'from': from.trim(),
      'to': to.trim(),
      'when': whenIso,
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

  /// BOOK a ride
  /// Expected backend: POST /rides/:id/book  (adjust below if your backend differs)
  Future<void> book(String rideId) async {
    final r = await http.post(
      _u('/rides/$rideId/book'),
      headers: {'Content-Type': 'application/json'},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('Book failed (${r.statusCode}): ${r.body}');
    }
  }

  /// YOUR RIDES (driver’s published rides or booking history)
  /// Example backend: GET /rides?driverName=John
  Future<List<Ride>> myRides({String? driverName}) async {
    final r = await http.get(_u('/rides', {
      if (driverName != null && driverName.trim().isNotEmpty)
        'driverName': driverName.trim(),
    }));

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
