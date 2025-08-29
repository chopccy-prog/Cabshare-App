// lib/models/ride.dart
class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime when;
  final int seats;
  final int price;
  final String driverName;
  final String? phone;
  final String? car;

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.seats,
    required this.price,
    required this.driverName,
    this.phone,
    this.car,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    // Support id or _id
    final id = (json['id'] ?? json['_id'] ?? '').toString();

    // Prefer 'when' (ISO), else combine 'date' + optional 'time'
    DateTime? when;
    final whenStr = json['when']?.toString();
    if (whenStr != null && whenStr.isNotEmpty) {
      when = DateTime.tryParse(whenStr);
    }
    if (when == null && json['date'] != null) {
      final dateStr = json['date'].toString(); // yyyy-MM-dd expected
      final timeStr = (json['time'] ?? '00:00').toString(); // HH:mm
      when = DateTime.tryParse('${dateStr}T$timeStr:00');
      when ??= DateTime.tryParse('${dateStr}T00:00:00'); // fallback if only date
    }
    when ??= DateTime.now();

    return Ride(
      id: id,
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      when: when,
      seats: _toInt(json['seats'], 0),
      price: _toInt(json['price'], 0),
      driverName: json['driverName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      car: json['car']?.toString(),
    );
  }

  static int _toInt(Object? v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'when': when.toIso8601String(),
    'seats': seats,
    'price': price,
    'driverName': driverName,
    if (phone != null) 'phone': phone,
    if (car != null) 'car': car,
  };
}
