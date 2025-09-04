// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
// If you have supabase_flutter in pubspec, this import will work; otherwise just remove the block using it.
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

class ApiError implements Exception {
  final int status;
  final String body;
  ApiError(this.status, this.body);
  @override
  String toString() => 'ApiError($status): $body';
}

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ??
      const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000'),
        _http = httpClient ?? http.Client();

  // ---------- core ----------
  Uri _u(String path, [Map<String, dynamic>? q]) {
    final root = Uri.parse(baseUrl);
    final rootPath = (root.path.isEmpty || root.path == '/') ? '' : root.path;
    final joinedPath = path.startsWith('/') ? '$rootPath$path' : '$rootPath/$path';
    return root.replace(
      path: joinedPath,
      queryParameters: q?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    // attach Supabase access token if available
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    } catch (_) {/* supabase not linked; ignore */}
    return h;
  }

  Future<http.Response> _get(String path, [Map<String, dynamic>? q]) =>
      _http.get(_u(path, q), headers: _headers(json: false));

  Future<http.Response> _post(String path, Object body) =>
      _http.post(_u(path), headers: _headers(), body: jsonEncode(body));

  bool _looksHtml(http.Response r) =>
      (r.headers['content-type'] ?? '').toLowerCase().contains('text/html');

  Future<T> _decodeOk<T>(http.Response r, {bool decodeJson = true}) async {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return (decodeJson ? jsonDecode(r.body) : r.body) as T;
    }
    throw ApiError(r.statusCode, r.body);
  }

  /// Try multiple endpoints until one returns 2xx (skips 404/HTML pages).
  Future<T> _getTry<T>(List<String> paths, {Map<String, dynamic>? q}) async {
    ApiError? last;
    for (final p in paths) {
      final res = await _get(p, q);
      if (res.statusCode >= 200 && res.statusCode < 300 && !_looksHtml(res)) {
        return _decodeOk<T>(res);
      }
      if (res.statusCode == 404 || _looksHtml(res)) {
        last = ApiError(res.statusCode, res.body);
        continue;
      }
      // non-404 errors are meaningful (401, 500 etc.)
      return _decodeOk<T>(res);
    }
    throw last ?? ApiError(404, 'Not Found');
  }

  Future<T> _postTry<T>(List<String> paths, Object body) async {
    ApiError? last;
    for (final p in paths) {
      final res = await _post(p, body);
      if (res.statusCode >= 200 && res.statusCode < 300 && !_looksHtml(res)) {
        return _decodeOk<T>(res);
      }
      if (res.statusCode == 404 || _looksHtml(res)) {
        last = ApiError(res.statusCode, res.body);
        continue;
      }
      return _decodeOk<T>(res);
    }
    throw last ?? ApiError(404, 'Not Found');
  }

  // ---------- rides: publish / my ----------
  Future<dynamic> publishRide({
    String? fromLocation,
    String? toLocation,
    String? fromCity,
    String? toCity,
    required String departDate, // yyyy-MM-dd
    required String departTime, // HH:mm
    int? seats,
    int? seatsTotal,            // alias
    int? price,
    int? pricePerSeatInr,       // alias
    String? rideType,           // passthrough
    String? carType,
    String? notes,
  }) {
    final fromVal = (fromLocation ?? fromCity ?? '').trim();
    final toVal = (toLocation ?? toCity ?? '').trim();
    final seatsValue = seats ?? seatsTotal;
    final priceValue = price ?? pricePerSeatInr;
    if (fromVal.isEmpty || toVal.isEmpty) {
      throw ArgumentError('fromLocation/fromCity and toLocation/toCity are required.');
    }
    if (seatsValue == null) throw ArgumentError('seats (or seatsTotal) is required.');
    if (priceValue == null) throw ArgumentError('price (or pricePerSeatInr) is required.');

    final body = {
      'fromLocation': fromVal,
      'toLocation': toVal,
      'departDate': departDate,
      'departTime': departTime,
      'seats': seatsValue,
      'price': priceValue,
      if (rideType != null && rideType.isNotEmpty) 'rideType': rideType,
      if (carType != null && carType.isNotEmpty) 'carType': carType,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    return _postTry<dynamic>([
      '/rides/publish',
      '/api/rides/publish',
    ], body);
  }

  /// myRides('driver') / myRides('rider') / default 'all'
  Future<List<dynamic>> myRides([String role = 'all']) async {
    final data = await _getTry<dynamic>([
      '/me/rides',
      '/api/me/rides',
      '/rides/mine',
      '/api/rides/mine',
    ], q: {'role': role});
    return (data is List) ? data : <dynamic>[];
  }

  // ---------- search / details / booking ----------
  Future<List<dynamic>> searchRides({
    String? from,
    String? to,
    String? fromLocation,
    String? toLocation,
    String? date,
    String? departDate,
    String? when,   // alias for date
    int? seats,
  }) async {
    final q = <String, dynamic>{
      if ((fromLocation ?? from)?.trim().isNotEmpty == true) 'from': (fromLocation ?? from)!.trim(),
      if ((toLocation ?? to)?.trim().isNotEmpty == true) 'to': (toLocation ?? to)!.trim(),
      if ((departDate ?? date ?? when)?.trim().isNotEmpty == true) 'date': (departDate ?? date ?? when)!.trim(),
      if (seats != null) 'seats': seats,
    };
    final data = await _getTry<dynamic>([
      '/rides/search',
      '/api/rides/search',
    ], q: q);
    return (data is List) ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> getRide(String rideId) async {
    final data = await _getTry<dynamic>([
      '/rides/$rideId',
      '/api/rides/$rideId',
    ]);
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestBooking(String rideId, int seats) async {
    final data = await _postTry<dynamic>([
      '/rides/$rideId/bookings',
      '/api/rides/$rideId/bookings',
    ], {'seats': seats});
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  // ---------- inbox / messages ----------
  Future<List<dynamic>> inbox() async {
    final data = await _getTry<dynamic>([
      '/me/inbox',
      '/api/me/inbox',
      '/inbox',
      '/api/inbox',
    ]);
    return (data is List) ? data : <dynamic>[];
  }

  Future<List<dynamic>> messages(String rideId, String otherUserId) async {
    final data = await _getTry<dynamic>([
      '/rides/$rideId/messages',
      '/api/rides/$rideId/messages',
      '/messages', // fallback (expects server to infer rideId via query)
      '/api/messages',
    ], q: {'otherUserId': otherUserId, 'rideId': rideId});
    return (data is List) ? data : <dynamic>[];
  }

  Future<void> sendMessage(String rideId, String otherUserId, String text) async {
    await _postTry<String>([
      '/rides/$rideId/messages',
      '/api/rides/$rideId/messages',
      '/messages',
      '/api/messages',
    ], {'otherUserId': otherUserId, 'rideId': rideId, 'text': text});
  }

  // ---------- util ----------
  void dispose() => _http.close();
}
