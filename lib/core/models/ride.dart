class Ride {
  final String id;
  final String driverName;
  final String from;
  final String to;
  final DateTime when;
  final int price;
  final int seats;
  final String? car;

  Ride({
    required this.id,
    required this.driverName,
    required this.from,
    required this.to,
    required this.when,
    required this.price,
    required this.seats,
    this.car,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: (j['_id'] ?? j['id']).toString(),
    driverName: j['driverName'] ?? '',
    from: j['from'] ?? '',
    to: j['to'] ?? '',
    when: DateTime.parse(j['when']),
    price: (j['price'] is int) ? j['price'] : int.tryParse('${j['price']}') ?? 0,
    seats: (j['seats'] is int) ? j['seats'] : int.tryParse('${j['seats']}') ?? 1,
    car: j['car'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'driverName': driverName,
    'from': from,
    'to': to,
    'when': when.toIso8601String(),
    'price': price,
    'seats': seats,
    if (car != null) 'car': car,
  };
}
