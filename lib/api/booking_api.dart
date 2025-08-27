import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/booking.dart';

class BookingApi {
  static Future<Booking> createBooking({
    required String rideId,
    required String passengerId,
    int seats = 1,
  }) async {
    final uri = Uri.parse('${Config.baseUrl}/bookings');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rideId': rideId,
        'passengerId': passengerId,
        'seats': seats,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Booking failed: ${res.statusCode} ${res.body}');
    }
    return Booking.fromJson(jsonDecode(res.body));
  }

  static Future<List<Booking>> myBookings(String passengerId) async {
    final uri = Uri.parse('${Config.baseUrl}/bookings?passengerId=$passengerId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Fetch bookings failed: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(Booking.fromJson).toList();
  }
}
