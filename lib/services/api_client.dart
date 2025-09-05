import 'dart:convert';
import 'package:http/http.dart' as http;

/// A lightweight HTTP client for the Work Setu‑Cab Share Flutter app.
///
/// This client wraps the backend REST API and handles details such as
/// authorization headers, query parameter encoding, and JSON decoding.
/// It also converts between the camelCase naming used in Flutter widgets
/// and the snake_case expected by the Node/Express backend.
class ApiClient {
  final String baseUrl;
  final http.Client _http = http.Client();

  /// Optional bearer token from Supabase auth.  Set this after login
  /// using [setAuthToken] so authenticated endpoints work correctly.
  String? _authToken;

  ApiClient({required this.baseUrl});

  /// Set or clear the authorization token.  Pass `null` to clear.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Build default headers for all requests.
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final tok = _authToken;
    if (tok != null && tok.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tok';
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Rides: search by from/to/date/type
  Future<List<dynamic>> searchRides({String? from, String? to, String? when, String? type}) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    if (when != null && when.isNotEmpty) qp['when'] = when;
    if (type != null && type.isNotEmpty) qp['type'] = type;
    final uri = Uri.parse('$baseUrl/rides/search').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Rides: publish a ride
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departAt,
    required int seats,
    required int pricePerSeatInr,
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
    };
    if (carPlate != null) body['car_plate'] = carPlate;
    if (carModel != null) body['car_model'] = carModel;
    final uri = Uri.parse('$baseUrl/rides');
    final resp = await _http.post(uri, headers: defaultHeaders, body: jsonEncode(body));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Rides: fetch a single ride
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final resp = await _http.get(Uri.parse('$baseUrl/rides/$rideId'), headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Bookings: request a booking
  Future<Map<String, dynamic>> requestBooking(
      String rideId,
      int seats, {
        String? uid,
        String? pickupStopId,
        String? dropStopId,
      }) async {
    final qp = <String, String>{};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri = Uri.parse('$baseUrl/bookings').replace(queryParameters: qp.isEmpty ? null : qp);
    final body = <String, dynamic>{
      'ride_id': rideId,
      'seats_requested': seats, // note: use seats_requested to match DB
    };
    if (pickupStopId != null) body['pickup_stop_id'] = pickupStopId;
    if (dropStopId != null) body['drop_stop_id'] = dropStopId;
    final resp = await _http.post(uri, headers: defaultHeaders, body: jsonEncode(body));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Routes: list routes between two cities
  Future<List<dynamic>> getRoutes({String? from, String? to}) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    final uri = Uri.parse('$baseUrl/routes').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Routes: list stops for a route
  Future<List<dynamic>> getRouteStops(String routeId) async {
    final uri = Uri.parse('$baseUrl/routes/$routeId/stops');
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Rides: get my rides (published or booked)
  Future<List<dynamic>> myRides({String role = 'driver', String? uid}) async {
    final qp = <String, String>{'role': role};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri = Uri.parse('$baseUrl/rides/mine').replace(queryParameters: qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Bookings: inbox (pending/confirmed bookings for rider or driver)
  Future<List<dynamic>> inbox({String? uid}) async {
    final qp = <String, String>{};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri = Uri.parse('$baseUrl/bookings/inbox').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Profiles: get current user profile
  Future<Map<String, dynamic>> getProfile({String? uid}) async {
    final qp = <String, String>{};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri = Uri.parse('$baseUrl/profiles/me').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Profiles: update current user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields, {String? uid}) async {
    final qp = <String, String>{};
    if (uid != null && uid.isNotEmpty) qp['uid'] = uid;
    final uri = Uri.parse('$baseUrl/profiles/me').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.put(uri, headers: defaultHeaders, body: jsonEncode(fields));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Messages: list all messages in a conversation (optional; not yet used)
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final uri = Uri.parse('$baseUrl/messages')
        .replace(queryParameters: {'ride_id': rideId, 'other_user_id': otherUserId});
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // Messages: send a message (optional; not yet used)
  Future<Map<String, dynamic>> sendMessage(
      String rideId,
      String recipientId,
      String text,
      ) async {
    final body = {
      'ride_id': rideId,
      'recipient_id': recipientId,
      'body': text,
    };
    final uri = Uri.parse('$baseUrl/messages');
    final resp = await _http.post(uri, headers: defaultHeaders, body: jsonEncode(body));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
