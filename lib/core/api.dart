// lib/core/api.dart
// This file now redirects to the proper ApiClient for compatibility

import '../services/api_client.dart';
export '../services/api_client.dart';

// Legacy Ride class for backward compatibility
class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime when;
  final int price;
  final int spots;
  final int? cashbackPct;

  const Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.price,
    required this.spots,
    this.cashbackPct,
  });

  String get dateLabel => '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}';
  String get timeLabel => '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

  Ride copyWith({int? spots}) => Ride(
    id: id, from: from, to: to, when: when, price: price,
    spots: spots ?? this.spots, cashbackPct: cashbackPct,
  );

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: j['id'].toString(),
    from: j['from'] ?? j['from_location'] ?? '',
    to: j['to'] ?? j['to_location'] ?? '',
    when: DateTime.tryParse(j['when'] ?? j['depart_at'] ?? '') ?? DateTime.now(),
    price: j['price'] ?? j['price_per_seat_inr'] ?? 0,
    spots: j['spots'] ?? j['seats_available'] ?? 0,
    cashbackPct: j['cashback_pct'],
  );
}

// Legacy Api class - now uses ApiClient internally
class Api {
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000');
  
  static final _client = ApiClient(baseUrl: baseUrl);

  static Future<List<Ride>> searchRides({
    required String from,
    required String to,
    DateTime? date,
  }) async {
    final results = await _client.searchRides(
      from: from,
      to: to,
      fromDate: date,
    );
    return results.map((e) => Ride.fromJson(e)).toList();
  }

  static Future<void> bookRide(String rideId, {int seats = 1}) async {
    await _client.requestBooking(rideId, seats);
  }
}
