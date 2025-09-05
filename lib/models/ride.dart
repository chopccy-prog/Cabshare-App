// lib/models/ride.dart
class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime when;
  final int seats;
  final num price;
  final String driverName; // may be blank if backend omits
  final String? driverPhone;
  final bool booked;
  final String pool; // keep as string to align with server 'private|commercial|commercial_private'

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.seats,
    required this.price,
    required this.driverName,
    required this.driverPhone,
    required this.booked,
    required this.pool,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    // Server returns ISO datetime string under key 'when'
    final whenStr = (json['when'] ?? json['depart_at'] ?? '').toString();
    final parsedWhen = DateTime.tryParse(whenStr) ?? DateTime.now();

    return Ride(
      id: (json['id'] ?? '').toString(),
      from: (json['from'] ?? json['source'] ?? '').toString(),
      to: (json['to'] ?? json['destination'] ?? '').toString(),
      when: parsedWhen.toLocal(),
      seats: int.tryParse(json['seats']?.toString() ?? '') ?? (json['seats_available'] ?? 0) as int,
      price: num.tryParse(json['price']?.toString() ?? '') ?? (json['price_per_seat_inr'] ?? 0),
      driverName: (json['driverName'] ?? json['driver_name'] ?? '').toString(),
      driverPhone: (json['driverPhone'] ?? json['driver_phone'])?.toString(),
      booked: (json['booked'] is bool)
          ? json['booked'] as bool
          : (json['booked']?.toString() == 'true'),
      pool: (json['pool'] ?? 'private').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'when': when.toUtc().toIso8601String(),
      'seats': seats,
      'price': price,
      'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'booked': booked,
      'pool': pool,
    };
  }
}
