class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime when;
  final int seats;
  final double price;
  final String driverName;
  final String? driverPhone;
  final bool? booked;

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.when,
    required this.seats,
    required this.price,
    required this.driverName,
    this.driverPhone,
    this.booked,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    // Parse time: accept either 'when' (ISO) OR 'date' + 'time'
    DateTime? when;

    final w = json['when'];
    if (w is String && w.isNotEmpty) {
      when = DateTime.tryParse(w);
    }

    if (when == null) {
      final dateStr = (json['date'] ?? '').toString();
      final timeStr = (json['time'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        if (timeStr.isNotEmpty) {
          // Correct ISO with a literal 'T' between date and time
          when = DateTime.tryParse('${dateStr}T$timeStr:00');
        }
        // Fallback to midnight if time missing/unparseable
        when ??= DateTime.tryParse('${dateStr}T00:00:00');
      }
    }

    when ??= DateTime.now();

    // seats can come as 'seats' or sometimes 'availableSeats'
    int seatsVal = 0;
    final seatsRaw = json['seats'];
    if (seatsRaw is int) {
      seatsVal = seatsRaw;
    } else {
      seatsVal = int.tryParse(seatsRaw?.toString() ?? '') ??
          int.tryParse(json['availableSeats']?.toString() ?? '') ??
          0;
    }

    final priceVal = double.tryParse(json['price']?.toString() ?? '') ?? 0.0;

    return Ride(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      when: when,
      seats: seatsVal,
      price: priceVal,
      driverName: (json['driverName'] ?? json['driver'] ?? '').toString(),
      driverPhone: json['driverPhone']?.toString(),
      booked: json['booked'] is bool ? json['booked'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'when': when.toIso8601String(),
    'seats': seats,
    'price': price,
    'driverName': driverName,
    if (driverPhone != null) 'driverPhone': driverPhone,
    if (booked != null) 'booked': booked,
  };
}
