// lib/features/rides/services/ride_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import '../models/ride.dart';

class RideService {
  final _base = ApiClient.baseUrl;

  Future<List<Ride>> search({
    String? from,
    String? to,
    DateTime? date,
  }) async {
    final uri = Uri.parse('$_base/rides/search');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
        if (date != null) 'date': date.toIso8601String().substring(0, 10),
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Search failed: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(Ride.fromJson).toList();
  }

  Future<Ride> publish({
    required String from,
    required String to,
    required DateTime dateTime,
    required int seats,
    required double price,
    String? driverName,
    String? vehicle,
    String? notes,
  }) async {
    final uri = Uri.parse('$_base/rides');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'from': from,
        'to': to,
        'date': dateTime.toIso8601String().substring(0, 10),
        'time':
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        'seats': seats,
        'price': price,
        if (driverName != null) 'driverName': driverName,
        if (vehicle != null) 'vehicle': vehicle,
        if (notes != null) 'notes': notes,
      }),
    );
    if (resp.statusCode != 201) {
      throw Exception('Publish failed: ${resp.statusCode} ${resp.body}');
    }
    return Ride.fromJson(jsonDecode(resp.body));
  }

  Future<void> book({required String rideId, int seats = 1}) async {
    final uri = Uri.parse('$_base/rides/$rideId/book');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'seats': seats}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Book failed: ${resp.statusCode} ${resp.body}');
    }
  }
}
