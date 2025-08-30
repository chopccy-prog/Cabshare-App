// lib/core/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ride.dart';
import '../models/pool_type.dart';

class ApiClient {
  final String baseUrl;
  ApiClient({required this.baseUrl});

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$baseUrl$path').replace(
        queryParameters: q?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );

  // /search -> { ok, rides: [...] }
  Future<List<Ride>> search({
    String? from,
    String? to,
    DateTime? date,
    PoolType? pool,
    String? driverName,
  }) async {
    final q = <String, dynamic>{};
    if (from != null && from.isNotEmpty) q['from'] = from;
    if (to != null && to.isNotEmpty) q['to'] = to;
    if (date != null) q['date'] = date.toIso8601String().substring(0, 10);
    if (pool != null) q['pool'] = pool.apiValue;
    if (driverName != null && driverName.isNotEmpty) {
      q['driverName'] = driverName;
    }

    final res = await http.get(_u('/search', q));
    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['rides'] as List? ?? []);
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Publish ride: NO phone/driverName here.
  Future<Ride> publish({
    required String from,
    required String to,
    required DateTime when,
    required int seats,
    required num price,
    String? notes,
    PoolType pool = PoolType.private,
  }) async {
    final payload = {
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      'seats': seats,
      'price': price,
      'pool': pool.apiValue,
    };
    if (notes != null && notes.isNotEmpty) payload['notes'] = notes;

    final res = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Publish failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final ride = body['ride'] as Map<String, dynamic>;
    return Ride.fromJson(ride);
  }

  // /rides -> { ok, rides: [...] }
  Future<List<Ride>> myRides({String? driverName}) async {
    final q = <String, dynamic>{};
    if (driverName != null && driverName.isNotEmpty) {
      q['driverName'] = driverName;
    }
    final res = await http.get(_u('/rides', q));
    if (res.statusCode != 200) {
      throw Exception('MyRides failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['rides'] as List? ?? []);
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  // book supports both /book/:id and /rides/:id/book; we’ll use the first.
  Future<void> book(String rideId) async {
    final res = await http.post(_u('/book/$rideId'));
    if (res.statusCode != 200) {
      throw Exception('Book failed: ${res.statusCode} ${res.body}');
    }
  }

  // ---- chat (kept simple; matches backend) ----
  Future<List<Map<String, dynamic>>> conversations({String? user}) async {
    final q = <String, dynamic>{};
    if (user != null && user.isNotEmpty) q['user'] = user;
    final res = await http.get(_u('/conversations', q));
    if (res.statusCode != 200) {
      throw Exception('Conversations failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['conversations'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final res = await http.get(_u('/messages', {'conversationId': conversationId}));
    if (res.statusCode != 200) {
      throw Exception('Messages failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['messages'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String from,
    required String text,
  }) async {
    final res = await http.post(
      _u('/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversationId': conversationId, 'from': from, 'text': text}),
    );
    if (res.statusCode != 200) {
      throw Exception('sendMessage failed: ${res.statusCode}');
    }
  }
}
