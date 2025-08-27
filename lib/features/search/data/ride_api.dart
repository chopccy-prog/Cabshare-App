// lib/features/search/data/ride_api.dart
import 'dart:convert';
import '../../../core/services/api.dart';
import '../../../core/models/ride.dart';

class RideApi {
  static Future<List<Ride>> searchRides({
    required String from,
    required String to,
    required DateTime when,
  }) async {
    // Your backend may accept either query params or a POST body.
    // First try GET /rides?from=&to=&date=
    final dateStr = when.toIso8601String().substring(0, 10); // YYYY-MM-DD
    try {
      final res = await ApiClient.get('/rides', query: {
        'from': from,
        'to': to,
        // Many simple servers expect just date (not time)
        'date': dateStr,
      });
      final data = jsonDecode(res.body);
      if (data is Map && data['rides'] is List) {
        return Ride.listFromJson(data['rides']);
      }
      return Ride.listFromJson(data);
    } catch (_) {
      // Fallback to POST /rides/search
      final res = await ApiClient.post('/rides/search', {
        'from': from,
        'to': to,
        'date': dateStr,
      });
      final data = jsonDecode(res.body);
      if (data is Map && data['rides'] is List) {
        return Ride.listFromJson(data['rides']);
      }
      return Ride.listFromJson(data);
    }
  }

  static Future<Ride> createRide({
    required String from,
    required String to,
    required DateTime when,
    required int seats,
    required double price,
  }) async {
    // We send the generous JSON; backend can pick what it needs.
    final payload = {
      'from': from,
      'to': to,
      'when': when.toUtc().toIso8601String(),
      'date': when.toIso8601String().substring(0, 10),
      'time': '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
      'seats': seats,
      'price': price,
    };
    final res = await ApiClient.post('/rides', payload);
    final data = jsonDecode(res.body);
    if (data is Map && data['ride'] is Map) {
      return Ride.fromJson(Map<String, dynamic>.from(data['ride']));
    }
    return Ride.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<Ride>> myRides() async {
    final res = await ApiClient.get('/rides/mine');
    final data = jsonDecode(res.body);
    if (data is Map && data['rides'] is List) {
      return Ride.listFromJson(data['rides']);
    }
    return Ride.listFromJson(data);
  }
}
