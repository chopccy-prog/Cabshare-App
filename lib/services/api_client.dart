// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read from --dart-define=API_BASE=http://<LAN-IP>:3000
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:3000',
);

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'API $status: $message';
}

class ApiClient {
  final String baseUrl;
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? kApiBase;

  SupabaseClient get _sb => Supabase.instance.client;

  Future<Map<String, String>> defaultHeaders({bool json = true}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = _sb.auth.currentSession?.accessToken;
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ------------------ SEARCH --------------------------------------------------
  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? when, // YYYY-MM-DD
  }) async {
    final qp = <String, String>{};
    if (from != null && from.trim().isNotEmpty) qp['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty)     qp['to']   = to.trim();
    if (when != null && when.trim().isNotEmpty) qp['date'] = when.trim();

    final url = Uri.parse('$baseUrl/rides').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );

    final res = await http.get(url, headers: await defaultHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final v = jsonDecode(res.body);
      if (v is List) return v;
      return <dynamic>[];
    }
    throw ApiException(res.statusCode, res.body);
  }

  // ------------------ DETAILS -------------------------------------------------
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final url = Uri.parse('$baseUrl/rides/$rideId');
    final res = await http.get(url, headers: await defaultHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final v = jsonDecode(res.body);
      if (v is Map<String, dynamic>) return v;
      throw ApiException(500, 'bad_payload');
    }
    throw ApiException(res.statusCode, res.body);
  }
// ------------------ PUBLISH -------------------------------------------------
  /// Backward-compatible publish that also accepts `rideType` from tab_publish.dart.
  ///
  /// Accepts BOTH old and new names used across screens:
  /// - fromLocation/fromCity, toLocation/toCity
  /// - date/departDate, time/departTime
  /// - seats/seatsTotal
  /// - pricePerSeatInr/priceInr/price_per_seat_inr
  /// - category OR rideType (enum/string/int)
  Future<Map<String, dynamic>> publishRide({
    // from / to (accept both)
    String? fromLocation,
    String? fromCity,
    String? toLocation,
    String? toCity,

    // date / time (accept both)
    String? date,        // YYYY-MM-DD
    String? departDate,  // YYYY-MM-DD
    String? time,        // HH:mm
    String? departTime,  // HH:mm or HH:mm:ss

    // seats / price (accept several spellings)
    int? seats,
    int? seatsTotal,
    int? priceInr,
    int? price_per_seat_inr,
    int? pricePerSeatInr,

    // either of these may be provided by different screens
    String? category,    // 'private_pool' | 'commercial_pool' | 'commercial_full_car'
    dynamic rideType,    // enum | string | int (0/1/2)

    // optional direct flags if some other screen provides them
    bool? isCommercial,
    String? pool, // 'shared' | 'private'
  }) async {
    final from = (fromLocation ?? fromCity ?? '').trim();
    final to   = (toLocation   ?? toCity   ?? '').trim();
    final d    = (departDate ?? date ?? '').trim();
    final t    = (departTime ?? time ?? '').trim();

    final seatCount = seatsTotal ?? seats ?? 0;
    final price     = pricePerSeatInr ?? priceInr ?? price_per_seat_inr ?? 0;

    // normalize rideType/category → 'private_pool' | 'commercial_pool' | 'commercial_full_car'
    String _normalizeKind(dynamic rt, String? cat) {
      if (cat != null && cat.isNotEmpty) return cat.toLowerCase();
      if (rt == null) return 'private_pool';

      if (rt is String) {
        final s = rt.toLowerCase().replaceAll(' ', '_');
        return (s == 'private_pool' || s == 'commercial_pool' || s == 'commercial_full_car')
            ? s
            : s.contains('full') ? 'commercial_full_car'
            : s.contains('commercial') ? 'commercial_pool'
            : 'private_pool';
      }
      // enum like RideCategory.privatePool → "RideCategory.privatePool"
      final s = rt.toString(); // e.g., "RideCategory.privatePool" or "0"
      final last = s.contains('.') ? s.split('.').last : s;
      final lower = last.toLowerCase();
      if (lower == 'privatepool') return 'private_pool';
      if (lower == 'commercialpool') return 'commercial_pool';
      if (lower == 'commercialfullcar' || lower == 'fullcar' || lower == 'full') return 'commercial_full_car';

      // int mapping 0/1/2
      if (int.tryParse(last) != null) {
        switch (int.parse(last)) {
          case 2: return 'commercial_full_car';
          case 1: return 'commercial_pool';
          case 0:
          default: return 'private_pool';
        }
      }
      return 'private_pool';
    }

    final kind = _normalizeKind(rideType, category);

    // derive commercial/pool from kind if not explicitly given
    bool derivedCommercial;
    String derivedPool;
    switch (kind) {
      case 'commercial_full_car':
        derivedCommercial = true;  derivedPool = 'private'; break;
      case 'commercial_pool':
        derivedCommercial = true;  derivedPool = 'shared';  break;
      case 'private_pool':
      default:
        derivedCommercial = false; derivedPool = 'shared';
    }
    final bool finalCommercial = isCommercial ?? derivedCommercial;
    final String finalPool     = pool ?? derivedPool;

    if (from.isEmpty || to.isEmpty || d.isEmpty || seatCount <= 0 || price < 0) {
      throw ApiException(400, 'missing required fields');
    }

    final body = {
      'from': from,
      'to': to,
      'depart_date': d,
      if (t.isNotEmpty) 'depart_time': t,
      'seats_total': seatCount,
      'seats_available': seatCount,
      'price_inr': price,
      'is_commercial': finalCommercial,
      'pool': finalPool,
      'category': kind, // send normalized kind for server logging/debug
    };

    final res = await http.post(
      Uri.parse('$baseUrl/rides'),
      headers: await defaultHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final v = jsonDecode(res.body);
      if (v is Map<String, dynamic>) return v;
      throw ApiException(500, 'bad_payload');
    }
    throw ApiException(res.statusCode, res.body);
  }

  // ------------------ BOOK ----------------------------------------------------
  Future<void> requestBooking(String rideId, int seats) async {
    final url = Uri.parse('$baseUrl/rides/$rideId/book');
    final res = await http.post(
      url,
      headers: await defaultHeaders(),
      body: jsonEncode({'seats': seats}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(res.statusCode, res.body);
  }

  // ------------------ YOUR RIDES ---------------------------------------------
  Future<List<dynamic>> myRides([String role = 'driver']) async {
    final url = Uri.parse('$baseUrl/rides/mine').replace(queryParameters: {'role': role});
    final res = await http.get(url, headers: await defaultHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final v = jsonDecode(res.body);
      if (v is List) return v;
      return <dynamic>[];
    }
    throw ApiException(res.statusCode, res.body);
  }

  // ------------------ INBOX (compat for your tab_inbox.dart) -----------------
  /// If the backend doesn't have /rides/messages* yet, return [] so UI works.
  Future<List<dynamic>> inbox() async {
    final url = Uri.parse('$baseUrl/rides/messages/inbox');
    try {
      final res = await http.get(url, headers: await defaultHeaders());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final v = jsonDecode(res.body);
        if (v is List) return v;
        return <dynamic>[];
      }
      if (res.statusCode == 404) return <dynamic>[];
      throw ApiException(res.statusCode, res.body);
    } catch (_) {
      return <dynamic>[];
    }
  }

  /// Message thread for a specific ride + other user
  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final url = Uri.parse('$baseUrl/rides/messages')
        .replace(queryParameters: {'ride_id': rideId, 'other': otherUserId});
    try {
      final res = await http.get(url, headers: await defaultHeaders());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final v = jsonDecode(res.body);
        if (v is List) return v;
        return <dynamic>[];
      }
      if (res.statusCode == 404) return <dynamic>[];
      throw ApiException(res.statusCode, res.body);
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<void> sendMessage(String rideId, String otherUserId, String text) async {
    final url = Uri.parse('$baseUrl/rides/messages');
    final body = {'ride_id': rideId, 'recipient_id': otherUserId, 'text': text};
    try {
      final res = await http.post(url, headers: await defaultHeaders(), body: jsonEncode(body));
      if (res.statusCode >= 200 && res.statusCode < 300) return;
      if (res.statusCode == 404) return;
      throw ApiException(res.statusCode, res.body);
    } catch (_) {
      return;
    }
  }
}
