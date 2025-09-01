import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  /// Final base URL for your backend, e.g. http://192.168.1.35:3000
  final String baseUrl;

  // Keep backward compatibility: old code calls ApiClient() with no args.
  ApiClient._internal(this.baseUrl);
  factory ApiClient() {
    // Read from --dart-define=API_BASE=...
    final fromEnv = const String.fromEnvironment('API_BASE', defaultValue: '');
    final base = (fromEnv.isNotEmpty) ? fromEnv : 'http://192.168.1.35:3000';
    return ApiClient._internal(base);
  }
  // Optional: if you ever want to pass an explicit base
  factory ApiClient.withBase(String base) => ApiClient._internal(base);

  // ------------------------------
  // Common helpers
  // ------------------------------
  Future<Map<String, String>> defaultHeaders() async {
    final auth = Supabase.instance.client.auth;
    final token = auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _itemsOf(Map<String, dynamic> j) {
    final v = j['items'];
    return (v is List) ? v : const <dynamic>[];
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // ------------------------------
  // Rides (search / publish / mine)
  // ------------------------------
  Future<List<dynamic>> searchRides({String? from, String? to, String? when}) async {
    final uri = Uri.parse('$baseUrl/rides/search').replace(queryParameters: {
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (when != null && when.isNotEmpty) 'when': when,
    });
    final res = await http.get(uri, headers: await defaultHeaders());
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    return _itemsOf(j);
  }

  /// Use the backend publish endpoint your app already calls.
  /// Payload should include from/to/date etc. (kept same as before).
  Future<Map<String, dynamic>?> publishRide(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/rides/publish');
    final res = await http.post(uri, headers: await defaultHeaders(), body: json.encode(payload));
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final r = j['ride'];
    return (r is Map<String, dynamic>) ? r : null;
  }

  /// Old usage in your code was: myRides('driver') / myRides('rider')
  Future<List<dynamic>> myRides(String role) async {
    final uri = Uri.parse('$baseUrl/rides/mine').replace(queryParameters: {'role': role});
    final res = await http.get(uri, headers: await defaultHeaders());
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    return _itemsOf(j);
  }

  // ------------------------------
  // Ride details + booking (new)
  // ------------------------------
  /// GET /rides/:id  -> ride with driver info
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final url = Uri.parse('$baseUrl/rides/$rideId');
    final res = await http.get(url, headers: await defaultHeaders());
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${jsonEncode(j)}');
    }
    return j;
  }

  /// POST /rides/:id/book { seat_count }
  Future<void> requestBooking(String rideId, int seatCount) async {
    final url = Uri.parse('$baseUrl/rides/$rideId/book');
    final res = await http.post(
      url,
      headers: await defaultHeaders(),
      body: json.encode({'seat_count': seatCount}),
    );
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }

  // ------------------------------
  // Inbox / Messages
  // ------------------------------
  /// Old code calls: messages(rideId, otherUserId)
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final url = Uri.parse('$baseUrl/messages')
        .replace(queryParameters: {'ride_id': rideId, 'other_user_id': otherUserId});
    final res = await http.get(url, headers: await defaultHeaders());
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    return _itemsOf(j);
  }
  /// List inbox items (conversations/messages) for the current user.
  /// Backend: GET $API_BASE/messages  -> { items: [...] }
  Future<List<dynamic>> inbox() async {
    final url = Uri.parse('$baseUrl/messages');
    final res = await http.get(url, headers: await defaultHeaders());
    final j = _decodeMap(res);
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    return _itemsOf(j);
  }

  /// Old code calls: sendMessage(rideId, otherUserId, text)
  Future<void> sendMessage(String rideId, String otherUserId, String text) async {
    final url = Uri.parse('$baseUrl/messages');
    final res = await http.post(
      url,
      headers: await defaultHeaders(),
      body: json.encode({
        'ride_id': rideId,
        'recipient_id': otherUserId,
        'text': text,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }
}
