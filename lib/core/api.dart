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
    from: j['from'],
    to: j['to'],
    when: DateTime.parse(j['when']),
    price: j['price'],
    spots: j['spots'],
    cashbackPct: j['cashback_pct'],
  );
}

class Api {
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://192.168.1.7:5000');

  static Future<List<Ride>> searchRides({
    required String from,
    required String to,
    DateTime? date,
  }) async {
    // GET /rides?from=&to=&date=YYYY-MM-DD
    final uri = Uri.parse('$baseUrl/rides').replace(queryParameters: {
      if (from.isNotEmpty) 'from': from,
      if (to.isNotEmpty) 'to': to,
      if (date != null) 'date': date.toIso8601String().substring(0, 10),
    });
    final res = await httpGet(uri);
    final data = res as List;
    return data.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> bookRide(String rideId) async {
    final uri = Uri.parse('$baseUrl/rides/$rideId/book');
    await httpPost(uri, body: const {});
  }

  // You already have these two helpers in your earlier setup, or similar
  static Future<dynamic> httpGet(Uri uri) async { /* ... */ }
  static Future<dynamic> httpPost(Uri uri, {Object? body}) async { /* ... */ }
}
