// lib/core/models/ride.dart
import 'dart:convert';

class Ride {
  final String id;
  final String from;
  final String to;
  /// UTC time from server; app will format to local.
  final DateTime when;
  final int seats;
  final double price;
  final String driverName;
  final String driverPhone; // optional
  final String car;         // optional

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.seats,
    required this.price,
    this.driverName = '',
    this.driverPhone = '',
    this.car = '',
  });

  /// Flexible factory that tolerates different backend keys.
  factory Ride.fromJson(Map<String, dynamic> j) {
    // id / _id
    final id = (j['id'] ?? j['_id'] ?? '').toString();

    // from/to or origin/destination
    final from = (j['from'] ?? j['origin'] ?? '').toString();
    final to   = (j['to']   ?? j['destination'] ?? '').toString();

    // when OR date+time
    DateTime when;
    if (j['when'] != null && j['when'].toString().isNotEmpty) {
      when = DateTime.tryParse(j['when'].toString()) ?? DateTime.now().toUtc();
    } else {
      final date = (j['date'] ?? '').toString(); // e.g. 2025-08-27
      final time = (j['time'] ?? '').toString(); // e.g. 14:30
      final combined = (date.isNotEmpty && time.isNotEmpty)
          ? '$dateT$time:00Z'
          : (date.isNotEmpty ? '${date}T00:00:00Z' : '');
      when = DateTime.tryParse(combined) ?? DateTime.now().toUtc();
    }

    // seats / available_seats
    int seats = 0;
    final seatsRaw = j['seats'] ?? j['available_seats'];
    if (seatsRaw is int) seats = seatsRaw;
    if (seatsRaw is String) seats = int.tryParse(seatsRaw) ?? 0;

    // price / amount
    double price = 0;
    final priceRaw = j['price'] ?? j['amount'];
    if (priceRaw is num) price = priceRaw.toDouble();
    if (priceRaw is String) price = double.tryParse(priceRaw) ?? 0;

    // driver/name fallbacks
    final driverObj = j['driver'] is Map ? (j['driver'] as Map) : null;
    final driverName =
    (j['driver_name'] ??
        driverObj?['name'] ??
        j['driverName'] ??
        '').toString();

    final driverPhone =
    (j['driver_phone'] ??
        driverObj?['phone'] ??
        j['driverPhone'] ??
        '').toString();

    final car =
    (j['car'] ??
        driverObj?['car'] ??
        '').toString();

    return Ride(
      id: id,
      from: from,
      to: to,
      when: when.toUtc(),
      seats: seats,
      price: price,
      driverName: driverName,
      driverPhone: driverPhone,
      car: car,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'when': when.toUtc().toIso8601String(),
    'seats': seats,
    'price': price,
    if (driverName.isNotEmpty) 'driver_name': driverName,
    if (driverPhone.isNotEmpty) 'driver_phone': driverPhone,
    if (car.isNotEmpty) 'car': car,
  };

  static List<Ride> listFromJson(dynamic data) {
    if (data is List) {
      return data.map((e) => Ride.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      return listFromJson(decoded);
    }
    return const [];
  }
}