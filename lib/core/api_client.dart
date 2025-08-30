import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride.dart';

class ApiClient {
  final String baseUrl;
  ApiClient({required this.baseUrl});

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

  Future<List<Ride>> search({
    String? from,
    String? to,
    DateTime? date,
    String? pool, // NEW: "private" | "commercial" | "fullcar"
  }) async {
    final q = <String, String>{};
    if (from != null && from.isNotEmpty) q['from'] = from;
    if (to != null && to.isNotEmpty) q['to'] = to;
    if (date != null) q['date'] = date.toIso8601String();
    if (pool != null && pool.isNotEmpty) q['pool'] = pool; // add to query

    final res = await http.get(_u('/search', q));
    _ensureOk(res);
    final data = jsonDecode(res.body);
    final list = (data is List ? data : (data['rides'] ?? [])) as List;
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> publish({
    required String from,
    required String to,
    required DateTime when,
    required String driverName,
    required String phone,            // <— added
    double? price,
    int? seats,
  }) async {
    final body = {
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      'driverName': driverName,
      'phone': phone,                  // <— sent to backend
      if (price != null) 'price': price,
      if (seats != null) 'seats': seats,
    };

    final res = await http.post(
      _u('/rides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(res);
  }

  Future<List<Ride>> myRides({String? driverName}) async {
    final q = <String, String>{};
    if (driverName != null && driverName.isNotEmpty) q['driverName'] = driverName;

    final res = await http.get(_u('/rides', q));
    _ensureOk(res);
    final data = jsonDecode(res.body);
    final list = (data is List ? data : (data['rides'] ?? [])) as List;
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> book(String rideId) async {
    final res = await http.post(
      _u('/rides/$rideId/book'),
      headers: {'Content-Type': 'application/json'},
    );
    _ensureOk(res);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
