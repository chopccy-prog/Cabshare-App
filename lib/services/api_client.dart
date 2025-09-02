// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base URL:
/// Prefer:  flutter run --dart-define=API_BASE_URL=http://192.168.1.35:3000
/// Legacy:  --dart-define=API_BASE=...  (we accept both)
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://192.168.1.35:3000',
  ),
);

class ApiClient {
  final String baseUrl;
  final Future<String?> Function()? tokenProvider;

  ApiClient({String? baseUrl, this.tokenProvider})
      : baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  /// Always attach:
  /// - Content-Type: application/json
  /// - Authorization: Bearer <supabase access token>  (if available)
  /// - x-user-id: <supabase user id>                  (if available)
  Future<Map<String, String>> defaultHeaders() async {
    final h = <String, String>{'Content-Type': 'application/json'};

    // Try the provided tokenProvider first
    String? token = await tokenProvider?.call();

    // Fallback to Supabase singleton (works even if tokenProvider not passed)
    final session = Supabase.instance.client.auth.currentSession;
    token ??= session?.accessToken;

    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    final uid = session?.user.id;
    if (uid != null && uid.isNotEmpty) {
      h['x-user-id'] = uid;
    }

    return h;
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : json.decode(res.body);
    }
    throw Exception('API ${res.statusCode}: ${res.body}');
  }

  // ---------- SEARCH ----------
  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? when, // YYYY-MM-DD
  }) async {
    final uri = Uri.parse('$baseUrl/rides/search').replace(queryParameters: {
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (when != null && when.isNotEmpty) 'date': when,
    });
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- RIDE DETAILS ----------
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final uri = Uri.parse('$baseUrl/rides/$rideId');
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  // ---------- PUBLISH RIDE ----------
  //
  // Keep UI param names exactly as used by TabPublish:
  //  - fromLocation, toLocation, departDate, departTime
  //  - pricePerSeatInr
  //  - seatsTotal | seats (either)
  //  - rideType: 'privatePool' | 'commercialPool' | 'commercialFullCar'
  // (Also supports explicit pool/isCommercial if rideType null)
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departDate, // YYYY-MM-DD
    required String departTime, // HH:mm
    required int pricePerSeatInr,
    int? seatsTotal,
    int? seats,
    String? rideType,
    String? pool,
    bool? isCommercial,
    int? priceInr, // legacy alias, ignored if pricePerSeatInr present
  }) async {
    final totalSeats = seatsTotal ?? seats ?? 1;
    final price = pricePerSeatInr != 0 ? pricePerSeatInr : (priceInr ?? 0);

    // Derive pool/isCommercial from rideType if provided
    String resolvedPool = pool ?? 'shared';
    bool resolvedCommercial = isCommercial ?? false;
    if (rideType != null) {
      switch (rideType) {
        case 'privatePool':
          resolvedPool = 'shared';
          resolvedCommercial = false;
          break;
        case 'commercialPool':
          resolvedPool = 'shared';
          resolvedCommercial = true;
          break;
        case 'commercialFullCar':
          resolvedPool = 'private';
          resolvedCommercial = true;
          break;
      }
    }

    final uri = Uri.parse('$baseUrl/rides');
    final body = {
      'from_location': fromLocation,
      'to_location': toLocation,
      'depart_date': departDate,
      'depart_time': departTime,
      'price_inr': price,
      'seats_total': totalSeats,
      'seats_available': totalSeats,
      'pool': resolvedPool,
      'is_commercial': resolvedCommercial,
    };

    final res = await http.post(
      uri,
      headers: await defaultHeaders(),
      body: json.encode(body),
    );
    final data = _handle(res);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  // ---------- YOUR RIDES ----------
  Future<List<dynamic>> myRides(String role) async {
    final uri =
    Uri.parse('$baseUrl/rides/mine').replace(queryParameters: {'role': role});
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- BOOKING ----------
  Future<Map<String, dynamic>> requestBooking(String rideId, int seats) async {
    final uri = Uri.parse('$baseUrl/rides/$rideId/book');
    final res = await http.post(
      uri,
      headers: await defaultHeaders(),
      body: json.encode({'seats': seats}),
    );
    final data = _handle(res);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  // ---------- INBOX ----------
  Future<List<dynamic>> inbox() async {
    final uri = Uri.parse('$baseUrl/inbox');
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- MESSAGES ----------
  // Use /messages to align with backend stubs; avoids 404 if /inbox/thread isn't present.
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final uri = Uri.parse('$baseUrl/messages')
        .replace(queryParameters: {'ride_id': rideId, 'other_id': otherUserId});
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> sendMessage(
      String rideId, String otherUserId, String text) async {
    final uri = Uri.parse('$baseUrl/messages');
    final res = await http.post(
      uri,
      headers: await defaultHeaders(),
      body: json.encode({
        'ride_id': rideId,
        'other_id': otherUserId,
        'text': text,
      }),
    );
    final data = _handle(res);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }
}
