// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  ApiClient({String? base})
      : base = base ?? const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000');

  final String base;

  String? _bearer;
  void setAuthToken(String? token) => _bearer = token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (_bearer != null) 'Authorization': 'Bearer $_bearer',
  };

  /// ===== Auth identity (Firebase) =====
  String? whoAmI() => FirebaseAuth.instance.currentUser?.uid;

  /// ===== Profiles =====
  Future<Map<String, dynamic>?> getProfile({String? uid}) async {
    final id = uid ?? whoAmI();
    if (id == null) return null;
    final r = await http.get(Uri.parse('$base/profiles?user_id=eq.$id'), headers: _headers());
    if (r.statusCode >= 400) throw Exception('getProfile: ${r.body}');
    final list = jsonDecode(r.body) as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> fields, {String? uid}) async {
    final id = uid ?? whoAmI();
    if (id == null) throw Exception('Not signed in');
    final body = {...fields, 'user_id': id};
    final r = await http.post(
      Uri.parse('$base/profiles'),
      headers: _headers()..putIfAbsent('Prefer', () => 'resolution=merge-duplicates,return=representation'),
      body: jsonEncode([body]),
    );
    if (r.statusCode >= 400) throw Exception('upsertProfile: ${r.body}');
    return (jsonDecode(r.body) as List).first as Map<String, dynamic>;
  }

  /// ===== Vehicles =====
  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> v) async {
    final uid = whoAmI();
    if (uid == null) throw Exception('Not signed in');
    final body = {...v, 'owner_id': uid};
    final r = await http.post(
      Uri.parse('$base/vehicles'),
      headers: _headers()..putIfAbsent('Prefer', () => 'return=representation'),
      body: jsonEncode([body]),
    );
    if (r.statusCode >= 400) throw Exception('addVehicle: ${r.body}');
    return (jsonDecode(r.body) as List).first;
  }

  Future<List<Map<String, dynamic>>> myVehicles() async {
    final uid = whoAmI();
    if (uid == null) return [];
    final r = await http.get(Uri.parse('$base/vehicles?owner_id=eq.$uid'), headers: _headers());
    if (r.statusCode >= 400) throw Exception('myVehicles: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  /// ===== Rides (reads view) =====
  Future<List<Map<String, dynamic>>> searchRides({
    required String fromCity,
    required String toCity,
    DateTime? fromDate,
  }) async {
    final qp = <String>[
      'from_city=eq.${Uri.encodeComponent(fromCity)}',
      'to_city=eq.${Uri.encodeComponent(toCity)}',
      if (fromDate != null) 'departure_at=gte.${fromDate.toIso8601String()}',
      'status=eq.published',
      'order=departure_at.asc',
    ].join('&');
    final r = await http.get(Uri.parse('$base/v_rides_list?$qp'), headers: _headers());
    if (r.statusCode >= 400) throw Exception('searchRides: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> myPublishedRides() async {
    final uid = whoAmI();
    if (uid == null) return [];
    final qp = 'driver_id=eq.$uid&status=eq.published&order=departure_at.desc';
    final r = await http.get(Uri.parse('$base/v_rides_list?$qp'), headers: _headers());
    if (r.statusCode >= 400) throw Exception('myPublishedRides: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  /// ===== Bookings =====
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
      'from_stop_id': fromStopId,
      'to_stop_id': toStopId,
      'seats_booked': seats,
      'fare_total_inr': total,
      'deposit_inr': dep,
      'status': autoApprove ? 'confirmed' : 'pending',
    };

    final r = await http.post(
      Uri.parse('$base/bookings'),
      headers: _headers()..putIfAbsent('Prefer', () => 'return=representation'),
      body: jsonEncode([payload]),
    );
    if (r.statusCode >= 400) throw Exception('createBooking: ${r.body}');
    return (jsonDecode(r.body) as List).first;
  }

  Future<List<Map<String, dynamic>>> myBookings() async {
    final uid = whoAmI();
    if (uid == null) return [];
    final r = await http.get(
      Uri.parse('$base/bookings?select=*,rides!inner(*)&rider_id=eq.$uid&order=created_at.desc'),
      headers: _headers(),
    );
    if (r.statusCode >= 400) throw Exception('myBookings: ${r.body}');
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }
}
