// lib/models/ride.dart
class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime when;
  final int seats;
  final num price;
  final String pool;

  // Optional (kept for forward compatibility; backend no longer requires/sends them)
  final String? driverName;
  final String? driverPhone;
  final bool? booked;
  final String? notes;

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.seats,
    required this.price,
    required this.pool,
    this.driverName,
    this.driverPhone,
    this.booked,
    this.notes,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    // backend returns { id, from, to, when(ISO), seats, price, pool, notes? }
    final whenStr = (json['when'] ?? '').toString();
    final dt = DateTime.tryParse(whenStr);
    return Ride(
      id: (json['id'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      when: dt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      seats: (json['seats'] ?? 0) is int
          ? json['seats'] as int
          : int.tryParse(json['seats'].toString()) ?? 0,
      price: (json['price'] ?? 0),
      pool: (json['pool'] ?? 'private').toString(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      booked: json['booked'] as bool?,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      'seats': seats,
      'price': price,
      'pool': pool,
    };
    if (driverName != null) map['driverName'] = driverName;
    if (driverPhone != null) map['driverPhone'] = driverPhone;
    if (booked != null) map['booked'] = booked;
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    return map;
  }
}
