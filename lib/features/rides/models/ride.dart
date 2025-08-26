// lib/features/rides/models/ride.dart
class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime dateTime;
  final int seatsAvailable;
  final double price;
  final String driverName;
  final String vehicle;
  final String notes;
  final int cashbackOnCancelPercent;

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.dateTime,
    required this.seatsAvailable,
    required this.price,
    required this.driverName,
    required this.vehicle,
    required this.notes,
    required this.cashbackOnCancelPercent,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: j['id'] as String,
    from: j['from'] as String,
    to: j['to'] as String,
    dateTime: DateTime.parse(j['dateTime'] as String),
    seatsAvailable: (j['seatsAvailable'] as num).toInt(),
    price: (j['price'] as num).toDouble(),
    driverName: (j['driverName'] ?? '') as String,
    vehicle: (j['vehicle'] ?? '') as String,
    notes: (j['notes'] ?? '') as String,
    cashbackOnCancelPercent: (j['cashbackOnCancelPercent'] ?? 0) as int,
  );
}
