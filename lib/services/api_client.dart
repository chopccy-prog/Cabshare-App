// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Unified API client that supports both the original REST endpoints
/// and the newer PostgREST-style views without breaking existing screens.
class ApiClient {
  // Keep the older constructor style working, but also allow env default.
  final String baseUrl;
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
      const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000');

  // Old code expects _http and defaultHeaders
  final http.Client _http = http.Client();

  String? _authToken; // optional bearer (Supabase/Firebase ID token)
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Old code uses this name — keep it.
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final tok = _authToken;
    if (tok != null && tok.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tok';
    }
    return headers;
  }

  /// Firebase identity helper used by "My Rides" / "My Bookings"
  String? whoAmI() => fb.FirebaseAuth.instance.currentUser?.uid;

  // ===========================================================================
  // Rides - SEARCH (old and new forms supported)
  //
  // Old UI used: from/to/when/type -> /rides/search
  // New view uses: fromCity/toCity/fromDate -> /v_rides_list
  Future<List<Map<String, dynamic>>> searchRides({
    // new style
    String? fromCity,
    String? toCity,
    DateTime? fromDate,

    // old style
    String? from,
    String? to,
    String? when,
    String? type,
  }) async {
    http.Response resp;

    if ((fromCity ?? '').isNotEmpty || (toCity ?? '').isNotEmpty || fromDate != null) {
      // New view path
      final qp = <String>[
        if ((fromCity ?? '').isNotEmpty) 'from_city=eq.${Uri.encodeComponent(fromCity!)}',
        if ((toCity ?? '').isNotEmpty) 'to_city=eq.${Uri.encodeComponent(toCity!)}',
        if (fromDate != null) 'departure_at=gte.${fromDate.toIso8601String()}',
        'status=eq.published',
        'order=departure_at.asc',
      ].join('&');
      final uri = Uri.parse('$baseUrl/v_rides_list?$qp');
      resp = await _http.get(uri, headers: defaultHeaders);
    } else {
      // Old search path
      final qp = <String, String>{};
      if ((from ?? '').isNotEmpty) qp['from'] = from!;
      if ((to ?? '').isNotEmpty) qp['to'] = to!;
      if ((when ?? '').isNotEmpty) qp['when'] = when!;
      if ((type ?? '').isNotEmpty) qp['type'] = type!;
      final uri = Uri.parse('$baseUrl/rides/search').replace(
        queryParameters: qp.isEmpty ? null : qp,
      );
      resp = await _http.get(uri, headers: defaultHeaders);
    }

    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
  }

  // ===========================================================================
  // Rides - PUBLISH (send both depart_at and departure_at to satisfy either schema)
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departAt, // ISO string
    required int seats,
    required int pricePerSeatInr,
    String rideType = 'private_pool',
    String? carPlate,
    String? carModel,
  }) async {
    final body = <String, dynamic>{
      'from_location': fromLocation,
      'to_location': toLocation,
      'depart_at': departAt,        // schema A
      'departure_at': departAt,     // schema B
      'seats_total': seats,
      'price_per_seat_inr': pricePerSeatInr,
      'ride_type': rideType,
      if (carPlate != null && carPlate.isNotEmpty) 'car_plate': carPlate,
      if (carModel != null && carModel.isNotEmpty) 'car_model': carModel,
    };
    final uri = Uri.parse('$baseUrl/rides');
    final resp = await _http.post(uri, headers: defaultHeaders, body: jsonEncode(body));
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ===========================================================================
  // Rides - GET single
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final resp = await _http.get(Uri.parse('$baseUrl/rides/$rideId'), headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ===========================================================================
  // Rides - "My Rides" (published for this driver)
  Future<List<Map<String, dynamic>>> myPublishedRides() async {
    final uid = whoAmI();
    if (uid == null) return [];
    // Works with the v_rides_list view
    final qp = 'driver_id=eq.$uid&status=eq.published&order=departure_at.desc';
    final r = await _http.get(Uri.parse('$baseUrl/v_rides_list?$qp'), headers: defaultHeaders);
    if (r.statusCode >= 400) throw Exception('myPublishedRides: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  // ===========================================================================
  // Bookings - old simple path used by RideDetail (keep it!)
  Future<Map<String, dynamic>> requestBooking(
      String rideId,
      int seats, {
        String? uid,
        String? pickupStopId,
        String? dropStopId,
      }) async {
    final effectiveUid = uid ?? whoAmI();
    // Delegate to createBooking with minimal info mapped
    final res = await createBooking(
      rideId: rideId,
      fromStopId: pickupStopId ?? '', // backend will ignore if not used
      toStopId: dropStopId ?? '',
      seats: seats,
      // Keep defaults
    );
    // Ensure rider_id if your backend needs it in body explicitly
    if (effectiveUid != null) res['rider_id'] = effectiveUid;
    return res;
  }

  // ===========================================================================
  // Bookings - detailed (new)
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
    if (uid == null) throw Exception('Not signed in');

    final perSeat = pricePerSeatInr ?? 0;
    final dep = depositInr ?? 0;
    final total = perSeat * seats;

    final payload = {
      'ride_id': rideId,
      'rider_id': uid,
      if (fromStopId.isNotEmpty) 'from_stop_id': fromStopId,
      if (toStopId.isNotEmpty) 'to_stop_id': toStopId,
      // keep both for compatibility
      'seats_booked': seats,
      'seats': seats,
      'fare_total_inr': total,
      'deposit_inr': dep,
      'status': autoApprove ? 'confirmed' : 'pending',
    };

    final r = await _http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        ...defaultHeaders,
        // If your backend is PostgREST this returns the inserted row
        'Prefer': 'return=representation',
      },
      body: jsonEncode([payload]),
    );
    if (r.statusCode >= 400) throw Exception('createBooking: ${r.body}');
    final list = jsonDecode(r.body);
    return (list is List && list.isNotEmpty) ? list.first as Map<String, dynamic> : <String, dynamic>{};
  }

  // ===========================================================================
  // Bookings - "My Bookings"
  Future<List<Map<String, dynamic>>> myBookings() async {
    final uid = whoAmI();
    if (uid == null) return [];
    final r = await _http.get(
      Uri.parse('$baseUrl/bookings?select=*,rides!inner(*)&rider_id=eq.$uid&order=created_at.desc'),
      headers: defaultHeaders,
    );
    if (r.statusCode >= 400) throw Exception('myBookings: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  // ===========================================================================
  // Inbox (pending/confirmed)
  Future<List<Map<String, dynamic>>> inbox({String? uid}) async {
    final id = uid ?? whoAmI();
    final qp = <String, String>{};
    if (id != null && id.isNotEmpty) qp['uid'] = id;
    final uri = Uri.parse('$baseUrl/bookings/inbox').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
  }

  // ===========================================================================
  // Routes (optional legacy)
  Future<List<dynamic>> getRoutes({String? from, String? to}) async {
    final qp = <String, String>{};
    if ((from ?? '').isNotEmpty) qp['from'] = from!;
    if ((to ?? '').isNotEmpty) qp['to'] = to!;
    final uri = Uri.parse('$baseUrl/routes').replace(queryParameters: qp.isEmpty ? null : qp);
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  Future<List<dynamic>> getRouteStops(String routeId) async {
    final uri = Uri.parse('$baseUrl/routes/$routeId/stops');
    final resp = await _http.get(uri, headers: defaultHeaders);
    if (resp.statusCode >= 400) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return (data is List) ? data : <dynamic>[];
  }

  // ===========================================================================
  // Profile (compatible with earlier usage)
  Future<Map<String, dynamic>> getProfile({String? uid}) async {
    final id = uid ?? whoAmI();
    if (id == null) throw Exception('Not signed in');
    // Try PostgREST pattern first
    final r = await _http.get(Uri.parse('$baseUrl/profiles?user_id=eq.$id'), headers: defaultHeaders);
    if (r.statusCode >= 400) throw Exception('getProfile: ${r.body}');
    final list = jsonDecode(r.body) as List;
    return list.isEmpty ? <String, dynamic>{} : list.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields, {String? uid}) async {
    final id = uid ?? whoAmI();
    if (id == null) throw Exception('Not signed in');
    final body = {...fields, 'user_id': id};
    final r = await _http.put(
      Uri.parse('$baseUrl/profiles/me'),
      headers: defaultHeaders,
      body: jsonEncode(body),
    );
    if (r.statusCode >= 400) throw Exception('updateProfile: ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ===========================================================================
  // Messages (optional; legacy, used by Inbox/testing)
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

  Future<Map<String, dynamic>> sendMessage(
      String rideId,
      String recipientId,
      String text,
      ) async {
    final body = <String, dynamic>{
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

