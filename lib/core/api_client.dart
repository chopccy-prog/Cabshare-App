import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models/ride.dart';

class ApiClient {
  final http.Client _c = http.Client();
  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('${AppConfig.baseUrl}$path').replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Future<List<Ride>> search({String? from, String? to, DateTime? date}) async {
    final r = await _c.get(_u('/rides', {
      if (from?.isNotEmpty == true) 'from': from,
      if (to?.isNotEmpty == true) 'to': to,
      if (date != null) 'date': date.toIso8601String(),
    }));
    if (r.statusCode != 200) throw Exception('GET /rides failed: ${r.statusCode} ${r.body}');
    final list = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(Ride.fromJson).toList();
  }

  Future<Ride> publish({
    required String driverName,
    required String from,
    required String to,
    required DateTime when,
    required int price,
    required int seats,
    String? car,
  }) async {
    final body = jsonEncode({
      'driverName': driverName,
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      'price': price,
      'seats': seats,
      if (car?.isNotEmpty == true) 'car': car,
    });
    final r = await _c.post(_u('/rides'),
        headers: {'Content-Type': 'application/json'}, body: body);
    if (r.statusCode != 201) throw Exception('POST /rides failed: ${r.statusCode} ${r.body}');
    return Ride.fromJson(jsonDecode(r.body));
  }

  Future<void> book(String rideId) async {
    final r = await _c.post(_u('/rides/$rideId/book'),
        headers: {'Content-Type': 'application/json'});
    if (r.statusCode != 200) throw Exception('POST /rides/:id/book failed: ${r.statusCode} ${r.body}');
  }

  Future<List<Ride>> myRides({required String driverName}) async {
    final r = await _c.get(_u('/rides', {'driverName': driverName}));
    if (r.statusCode != 200) throw Exception('GET /rides?driverName= failed: ${r.statusCode} ${r.body}');
    final list = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(Ride.fromJson).toList();
  }
}
