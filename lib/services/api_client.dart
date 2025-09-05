import 'dart:convert';
import 'package:http/http.dart' as http;

/// Very small, stable client that matches the current backend routes.
/// - Keeps field names your backend expects
/// - Adds `when` to `searchRides` to satisfy tab_search.dart
class ApiClient {
  final String baseUrl;
  final http.Client _http = http.Client();

  ApiClient({required this.baseUrl});

  Map<String, String> get defaultHeaders => const {
    'Content-Type': 'application/json',
  };

  // ----------------- Rides: Search -----------------
  // tab_search.dart expects: from, to, when, type
  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? when,
    String? type,
  }) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    if (when != null && when.isNotEmpty) qp['when'] = when; // <- important
    if (type != null && type.isNotEmpty) qp['type'] = type;

    final uri = Uri.parse('$baseUrl/rides/search').replace(queryParameters: qp);
    final resp = await _http.get(uri, headers: defaultHeaders);

    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ----------------- Rides: Publish -----------------
  // Matches backend normalizer: from_location / to_location / depart_at / price_per_seat_inr / seats_total
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departAt, // ISO "YYYY-MM-DD HH:mm:ss" or "YYYY-MM-DD"
    required int seats, // seats_total
    required int pricePerSeatInr,
    String rideType = 'private',
    String? carRegNumber,
    String? carModel,
  }) async {
    final body = {
      'from_location': fromLocation,
      'to_location': toLocation,
      'depart_at': departAt,
      'seats_total': seats,
      'price_per_seat_inr': pricePerSeatInr,
      'ride_type': rideType,
      if (carRegNumber != null) 'car_reg_number': carRegNumber,
      if (carModel != null) 'car_model': carModel,
    };

    final resp = await _http.post(
      Uri.parse('$baseUrl/rides'),
      headers: defaultHeaders,
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ----------------- Rides: Get one -----------------
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final resp = await _http.get(
      Uri.parse('$baseUrl/rides/$rideId'),
      headers: defaultHeaders,
    );
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ----------------- Bookings: request -----------------
  // Backend expects: { ride_id, seats } and stores seats into seats_requested
  Future<Map<String, dynamic>> requestBooking(String rideId, int seats) async {
    final resp = await _http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: defaultHeaders,
      body: jsonEncode({
        'ride_id': rideId,
        'seats': seats,
      }),
    );
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ----------------- My rides (driver/rider tabs) -----------------
  // We keep your existing route: /rides/mine?role=driver|rider
  Future<List<dynamic>> myRides({String role = 'driver'}) async {
    final uri = Uri.parse('$baseUrl/rides/mine')
        .replace(queryParameters: {'role': role});
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ----------------- Inbox list -----------------
  Future<List<dynamic>> inbox() async {
    final resp =
    await _http.get(Uri.parse('$baseUrl/bookings/inbox'), headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ----------------- Messages: list conversation -----------------
  /// Get all messages exchanged with another user on a specific ride.
  /// Requires both `rideId` and the `otherUserId`.
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final uri = Uri.parse('$baseUrl/messages').replace(queryParameters: {
      'ride_id': rideId,
      'other_user_id': otherUserId,
    });
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ----------------- Messages: send a new message -----------------
  /// Send a message to another user on a ride.
  /// `recipientId` is the ID of the person you’re chatting with.
  Future<Map<String, dynamic>> sendMessage(
      String rideId, String recipientId, String text) async {
    final resp = await _http.post(
      Uri.parse('$baseUrl/messages'),
      headers: defaultHeaders,
      body: jsonEncode({
        'ride_id': rideId,
        'recipient_id': recipientId,
        'body': text,
      }),
    );
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

}
