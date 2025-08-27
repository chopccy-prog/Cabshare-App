// lib/models/ride.dart
import 'package:intl/intl.dart';

class Ride {
  final String id;
  final String driverName;
  final String fromCity;
  final double? fromLat;
  final double? fromLng;
  final String toCity;
  final double? toLat;
  final double? toLng;
  final DateTime when;
  final int price;
  final int seats;
  final String? car;

  Ride({
    required this.id,
    required this.driverName,
    required this.fromCity,
    this.fromLat,
    this.fromLng,
    required this.toCity,
    this.toLat,
    this.toLng,
    required this.when,
    required this.price,
    required this.seats,
    this.car,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: (j['id'] ?? j['_id'] ?? '').toString(),
    driverName: j['driverName'] ?? j['driver'] ?? 'Driver',
    fromCity: j['fromCity'] ?? j['from']?['city'] ?? j['from'] ?? '',
    fromLat: (j['fromLat'] ?? j['from']?['lat']) == null
        ? null
        : (j['fromLat'] ?? j['from']?['lat']).toDouble(),
    fromLng: (j['fromLng'] ?? j['from']?['lng']) == null
        ? null
        : (j['fromLng'] ?? j['from']?['lng']).toDouble(),
    toCity: j['toCity'] ?? j['to']?['city'] ?? j['to'] ?? '',
    toLat: (j['toLat'] ?? j['to']?['lat']) == null
        ? null
        : (j['toLat'] ?? j['to']?['lat']).toDouble(),
    toLng: (j['toLng'] ?? j['to']?['lng']) == null
        ? null
        : (j['toLng'] ?? j['to']?['lng']).toDouble(),
    when: DateTime.parse(j['when'] ?? j['date']),
    price: j['price'] is String ? int.tryParse(j['price']) ?? 0 : (j['price'] ?? 0),
    seats: j['seats'] is String ? int.tryParse(j['seats']) ?? 1 : (j['seats'] ?? 1),
    car: j['car'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'driverName': driverName,
    'fromCity': fromCity,
    'fromLat': fromLat,
    'fromLng': fromLng,
    'toCity': toCity,
    'toLat': toLat,
    'toLng': toLng,
    'when': when.toIso8601String(),
    'price': price,
    'seats': seats,
    'car': car,
  };

  String get prettyDate => DateFormat('EEE, d MMM • h:mm a').format(when);
}
