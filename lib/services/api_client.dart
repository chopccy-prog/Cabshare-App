// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Backend base URL (override at run time with --dart-define)
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.35:3000',
);

class ApiClient {
  final String baseUrl;
  final Future<String?> Function()? tokenProvider;

  ApiClient({String? baseUrl, this.tokenProvider})
      : baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  Future<Map<String, String>> defaultHeaders() async {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = await tokenProvider?.call();
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
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
  // Back-compat params supported by UI:
  //  - fromLocation, toLocation, departDate, departTime
  //  - pricePerSeatInr  (primary)  | priceInr (legacy)
  //  - seatsTotal | seats (either is fine)
  //  - rideType: "privatePool" | "commercialPool" | "commercialFullCar"
  // Newer explicit params (optional, used if rideType is null):
  //  - pool: "shared" | "private"
  //  - isCommercial: bool
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departDate, // YYYY-MM-DD
    required String departTime, // HH:mm
    required int pricePerSeatInr,
    int? seatsTotal,
    int? seats,

    // legacy UI param:
    String? rideType,

    // explicit (if rideType not provided):
    String? pool,
    bool? isCommercial,

    // legacy price alias (ignored if pricePerSeatInr is present)
    int? priceInr,
  }) async {
    // Seats
    final totalSeats = seatsTotal ?? seats ?? 1;

    // Price
    final price = pricePerSeatInr != 0 ? pricePerSeatInr : (priceInr ?? 0);

    // Derive pool + isCommercial from rideType if provided
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
        default:
        // keep provided pool/isCommercial defaults
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
  // role: 'driver' or 'rider'
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

  // ---------- INBOX LIST ----------
  Future<List<dynamic>> inbox() async {
    final uri = Uri.parse('$baseUrl/inbox');
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- MESSAGES THREAD ----------
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final uri = Uri.parse('$baseUrl/inbox/thread').replace(queryParameters: {
      'rideId': rideId,
      'otherUserId': otherUserId,
    });
    final res = await http.get(uri, headers: await defaultHeaders());
    final data = _handle(res);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- SEND MESSAGE ----------
  Future<Map<String, dynamic>> sendMessage(
      String rideId, String otherUserId, String text) async {
    final uri = Uri.parse('$baseUrl/inbox/send');
    final res = await http.post(
      uri,
      headers: await defaultHeaders(),
      body: json.encode({
        'ride_id': rideId,
        'to_user_id': otherUserId,
        'text': text,
      }),
    );
    final data = _handle(res);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }
}
