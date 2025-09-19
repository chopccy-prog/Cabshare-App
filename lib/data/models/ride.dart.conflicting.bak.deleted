class Ride {
  final String id;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departure;
  final int seats;
  final num price;

  Ride({
    required this.id,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.seats,
    required this.price,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: j['id'] as String,
    driverName: (j['driverName'] ?? '') as String,
    origin: j['origin'] as String,
    destination: j['destination'] as String,
    departure: DateTime.parse(j['departureIso'] as String),
    seats: (j['seats'] ?? 0) as int,
    price: (j['price'] ?? 0) as num,
  );
}
