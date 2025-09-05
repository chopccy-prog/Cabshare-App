import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight HTTP client for the Work Setu‑Cab Share Flutter app.
///
/// This client provides methods that mirror the backend routes.  It
/// centralizes default headers (including an optional Supabase
/// authentication token) and converts between camelCase parameters
/// exposed by the widgets and the snake_case keys expected by the
/// Node/Express API.
class ApiClient {
  final String baseUrl;
  final http.Client _http = http.Client();

  /// Optional access token used to authorize requests with the
  /// Supabase backend.  Call [setAuthToken] after signing in to
  /// automatically attach `Authorization: Bearer <token>` on every
  /// request.
  String? _authToken;

  ApiClient({required this.baseUrl});

  /// Update the bearer token used for authorization.  Passing `null`
  /// clears the token.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Compose default headers for every request.  Includes JSON
  /// content‑type and, if set, the Supabase bearer token.
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final tok = _authToken;
    if (tok != null && tok.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tok';
    }
    return headers;
  }

  // -----------------------------------------------------------------
  // Rides: Search
  //
  // Search rides by `from`, `to`, `when` (date), and `type`.  These
  // parameters map directly into the backend’s query string.  The
  // returned list contains raw JSON maps.
  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? when,
    String? type,
  }) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    if (when != null && when.isNotEmpty) qp['when'] = when;
    if (type != null && type.isNotEmpty) qp['type'] = type;
    final uri = Uri.parse('$baseUrl/rides/search').replace(queryParameters: qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // -----------------------------------------------------------------
  // Rides: Publish
  //
  // Publish a new ride.  Converts camelCase keys into the snake_case
  // fields expected by the backend.  Accepts a combined `departAt`
  // value (YYYY‑MM‑DD or YYYY‑MM‑DD HH:mm) and splits it on the
  // backend.  `rideType` defaults to `private`.
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departAt,
    required int seats,
    required int pricePerSeatInr,
    // Default to "private_pool" which is a valid value per the
    // rides_ride_type_check constraint in the database.
    String rideType = 'private_pool',
    String? carPlate,
    String? carModel,
  }) async {
    final body = <String, dynamic>{
      'from_location': fromLocation,
      'to_location': toLocation,
      'depart_at': departAt,
      'seats_total': seats,
      'price_per_seat_inr': pricePerSeatInr,
      'ride_type': rideType,
      if (carPlate != null) 'car_plate': carPlate,
      if (carModel != null) 'car_model': carModel,
    };
    final uri = Uri.parse('$baseUrl/rides');
    final resp = await _http.post(uri,
        headers: defaultHeaders, body: jsonEncode(body));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // -----------------------------------------------------------------
  // Rides: Get a single ride by ID
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

  // -----------------------------------------------------------------
  // Bookings: Request booking
  Future<Map<String, dynamic>> requestBooking(String rideId, int seats,
      {String? uid}) async {
    // Optionally pass uid as a query parameter when bearer auth is not available.
    final uri = Uri.parse('$baseUrl/bookings')
        .replace(queryParameters: uid != null && uid.isNotEmpty ? {'uid': uid} : null);
    final resp = await _http.post(
      uri,
      headers: defaultHeaders,
      body: jsonEncode({'ride_id': rideId, 'seats': seats}),
    );
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // -----------------------------------------------------------------
  // Rides: My rides (published or booked)
  Future<List<dynamic>> myRides({String role = 'driver', String? uid}) async {
    final qp = <String, String>{'role': role};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri =
    Uri.parse('$baseUrl/rides/mine').replace(queryParameters: qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // -----------------------------------------------------------------
  // Bookings: Inbox list
  Future<List<dynamic>> inbox({String? uid}) async {
    final uri = Uri.parse('$baseUrl/bookings/inbox').replace(
        queryParameters: uid != null && uid.isNotEmpty ? {'uid': uid} : null);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // -----------------------------------------------------------------
  // Messages: list conversation
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

  // -----------------------------------------------------------------
  // Messages: send a new message
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