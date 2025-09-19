// lib/core/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride.dart';
import '../models/pool_type.dart';

class ApiClient {
  final String baseUrl; // e.g. http://192.168.1.35:5000

  ApiClient({required this.baseUrl});

  Uri _u(String p, [Map<String, dynamic>? q]) =>
      Uri.parse('$baseUrl$p').replace(queryParameters: q?.map((k, v) => MapEntry(k, v?.toString())));

  Future<List<Ride>> search({
    String? from,
    String? to,
    DateTime? date, // date-only filter
    PoolType? pool,
    String? driverName,
  }) async {
    final q = <String, dynamic>{};
    if (from != null && from.isNotEmpty) q['from'] = from;
    if (to != null && to.isNotEmpty) q['to'] = to;
    if (date != null) {
      final yyyy = date.year.toString().padLeft(4, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final dd = date.day.toString().padLeft(2, '0');
      q['date'] = '$yyyy-$mm-$dd';
    }
    if (pool != null) q['pool'] = pool.name;
    if (driverName != null && driverName.isNotEmpty) q['driverName'] = driverName;

    final res = await http.get(_u('/rides', q));
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      final err = (body is Map && body['error'] != null) ? body['error'].toString() : 'search failed';
      throw Exception(err);
    }

    final list = (body['data'] as List?) ?? <dynamic>[];
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
    // NOTE: if server returns ambiguous result with 500, the error will be thrown above.
  }

  Future<void> publish({
    required String from,
    required String to,
    required DateTime when,
    required int seats,
    required num price,
    required PoolType pool,
  }) async {
    final payload = {
      'from': from,
      'to': to,
      'when': when.toUtc().toIso8601String(),
      'seats': seats,
      'price': price,
      'pool': pool.name,
      // NO phone/name here; your requirement says those come from profile later
    };

    final res = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      final err = (body is Map && body['error'] != null) ? body['error'].toString() : 'publish failed';
      throw Exception(err);
    }
  }

  Future<void> book(String rideId) async {
    final res = await http.post(_u('/rides/$rideId/book'));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      final err = (body is Map && body['error'] != null) ? body['error'].toString() : 'book failed';
      throw Exception(err);
    }
  }

  // Inbox / Chat
  Future<List<Map<String, dynamic>>> getConversations({String user = 'rider'}) async {
    final res = await http.get(_u('/conversations', {'user': user}));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      throw Exception((body is Map && body['error'] != null) ? body['error'] : 'conversations failed');
    }
    return (body['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final res = await http.get(_u('/messages', {'conversationId': conversationId}));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      throw Exception((body is Map && body['error'] != null) ? body['error'] : 'messages failed');
    }
    return (body['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String from,
    required String text,
  }) async {
    final res = await http.post(
      _u('/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversationId': conversationId, 'from': from, 'text': text}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      throw Exception((body is Map && body['error'] != null) ? body['error'] : 'send failed');
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  Future<List<Ride>> myRides({String? driverName}) async {
    final res = await http.get(_u('/my-rides', {'driverName': driverName ?? ''}));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
      throw Exception((body is Map && body['error'] != null) ? body['error'] : 'myRides failed');
    }
    final list = (body['data'] as List?) ?? <dynamic>[];
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }
}
