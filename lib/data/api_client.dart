import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$kBaseUrl$path').replace(queryParameters: q?.map((k,v) => MapEntry(k, '$v')));

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_u(path, query)).timeout(const Duration(seconds: 15));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      if (body is List) return body;
      throw 'Expected a list at $path';
    }
    throw 'GET $path failed: ${res.statusCode} ${res.body}';
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> data) async {
    final res = await http.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw 'POST $path failed: ${res.statusCode} ${res.body}';
  }
}
