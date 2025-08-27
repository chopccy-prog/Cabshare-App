// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/ride.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  /// Change this to your LAN IP
  String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.7:5000',
  );

  Uri _u(String p, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$p').replace(queryParameters: q);

  Future<bool> health() async {
    final r = await http.get(_u('/health'));
    return r.statusCode == 200 && (jsonDecode(r.body)['ok'] == true);
  }

  Future<List<Ride>> searchRides({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    final q = {
      'from': from,
      'to': to,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
    final r = await http.get(_u('/rides', q));
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final List data = jsonDecode(r.body);
      return data.map((e) => Ride.fromJson(e)).toList();
    }
    throw Exception('GET /rides failed: ${r.statusCode} ${r.body}');
  }

  Future<Ride> publishRide({
    required String driverName,
    required String fromCity,
    required String toCity,
    required DateTime when,
    required int price,
    required int seats,
    String? car,
  }) async {
    final r = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'driverName': driverName,
        'fromCity': fromCity,
        'toCity': toCity,
        'when': when.toIso8601String(),
        'price': price,
        'seats': seats,
        'car': car,
      }),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return Ride.fromJson(jsonDecode(r.body));
    }
    throw Exception('POST /rides failed: ${r.statusCode} ${r.body}');
  }

  Future<Map<String, dynamic>> bookRide(String rideId, {int seats = 1}) async {
    final r = await http.post(
      _u('/rides/$rideId/book'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'seats': seats}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception('POST /rides/$rideId/book failed: ${r.statusCode} ${r.body}');
  }
}
