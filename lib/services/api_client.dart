// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Blended ApiClient that supports both the older Node/Express endpoints
/// and the newer PostgREST-like patterns we tried, while keeping the app
/// screens working without changes.
class ApiClient {
  final String baseUrl;
  final http.Client _http = http.Client();

  String? _authToken; // optional bearer from Supabase/Firebase
  ApiClient({required this.baseUrl});

  void setAuthToken(String? token) => _authToken = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null && _authToken!.isNotEmpty)
      'Authorization': 'Bearer $_authToken',
  };

  /// Current Firebase user id (if signed in)
  String? whoAmI() => fb.FirebaseAuth.instance.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // SEARCH
  // Matches the Search screen: from/to/when/type
  Future<List<Map<String, dynamic>>> searchRides({
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

    final uri = Uri.parse('$baseUrl/rides/search')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('searchRides ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  // ---------------------------------------------------------------------------
  // ROUTES/STOPS (for Ride detail stop pickers)
  Future<List<Map<String, dynamic>>> getRouteStops(String routeId) async {
    final uri = Uri.parse('$baseUrl/routes/$routeId/stops');
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('getRouteStops ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  // ---------------------------------------------------------------------------
  // RIDES (publish + detail)
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
      if (carPlate != null) 'car_plate': carPlate,
      if (carModel != null) 'car_model': carModel,
    };
    final uri = Uri.parse('$baseUrl/rides');
    final r = await _http.post(uri, headers: _headers, body: jsonEncode(body));
    if (r.statusCode >= 400) {
      throw Exception('publishRide ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRide(String rideId) async {
    final uri = Uri.parse('$baseUrl/rides/$rideId');
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('getRide ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // BOOKINGS
  // Newer path used by RideDetail when we have explicit stop ids.
  Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required String fromStopId,
    required String toStopId,
    required int seats,
    bool autoApprove = false,
    int? pricePerSeatInr,
    int? depositInr,
  }) async {
    final uid = whoAmI();
    // Let backend compute money if not supplied
    final payload = {
      'ride_id': rideId,
      if (uid != null) 'rider_id': uid,
      // Support both naming styles (new vs old)
      'from_stop_id': fromStopId,
      'to_stop_id': toStopId,
      'pickup_stop_id': fromStopId,
      'drop_stop_id': toStopId,
      'seats_booked': seats,
      'seats_requested': seats,
      if (pricePerSeatInr != null) 'price_per_seat_inr': pricePerSeatInr,
      if (depositInr != null) 'deposit_inr': depositInr,
      if (autoApprove) 'status': 'confirmed',
    };

    final r = await _http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (r.statusCode >= 400) {
      throw Exception('createBooking ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Legacy fallback used by some screens.
  /// Keeps old signature so we don't have to touch UI.
  Future<Map<String, dynamic>> requestBooking(
      String rideId,
      int seats, {
        String? uid,
        String? pickupStopId,
        String? dropStopId,
      }) async {
    final rider = uid ?? whoAmI();
    final body = <String, dynamic>{
      'ride_id': rideId,
      if (rider != null) 'rider_id': rider,
      'seats_requested': seats,
      'seats': seats,
      if (pickupStopId != null) 'pickup_stop_id': pickupStopId,
      if (dropStopId != null) 'drop_stop_id': dropStopId,
    };

    final uri = Uri.parse('$baseUrl/bookings');
    final r = await _http.post(uri, headers: _headers, body: jsonEncode(body));
    if (r.statusCode >= 400) {
      throw Exception('requestBooking ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // MY RIDES / BOOKINGS (for "Your Rides" tab)
  Future<List<Map<String, dynamic>>> myPublishedRides() async {
    final uid = whoAmI();
    final qp = <String, String>{'role': 'driver', if (uid != null) 'uid': uid};
    final uri =
    Uri.parse('$baseUrl/rides/mine').replace(queryParameters: qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('myPublishedRides ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> myBookings() async {
    final uid = whoAmI();
    final qp = <String, String>{if (uid != null) 'uid': uid, 'role': 'rider'};
    final uri = Uri.parse('$baseUrl/bookings/inbox')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('myBookings ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  // ---------------------------------------------------------------------------
  // Optional existing endpoints kept for compatibility

  Future<List<Map<String, dynamic>>> getRoutes({
    String? from,
    String? to,
  }) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    final uri =
    Uri.parse('$baseUrl/routes').replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('getRoutes ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> inbox({String? uid}) async {
    final qp = <String, String>{if (uid != null) 'uid': uid};
    final uri = Uri.parse('$baseUrl/bookings/inbox')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('inbox ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body);
    return (data is List)
        ? data.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields,
      {String? uid}) async {
    final qp = <String, String>{if (uid != null) 'uid': uid};
    final uri = Uri.parse('$baseUrl/profiles/me')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r =
    await _http.put(uri, headers: _headers, body: jsonEncode(fields));
    if (r.statusCode >= 400) {
      throw Exception('updateProfile ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile({String? uid}) async {
    final qp = <String, String>{if (uid != null) 'uid': uid};
    final uri = Uri.parse('$baseUrl/profiles/me')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception('getProfile ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
