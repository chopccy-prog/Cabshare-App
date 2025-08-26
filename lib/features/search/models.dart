class Ride {
  final String id;
  final String from;
  final String to;
  final DateTime departure;
  final int seats;
  final double price;
  final String driver;

  Ride({
    required this.id,
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.price,
    required this.driver,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: j['id'].toString(),
    from: j['from'] as String,
    to: j['to'] as String,
    departure: DateTime.parse(j['departure']),
    seats: (j['seats'] as num).toInt(),
    price: (j['price'] as num).toDouble(),
    driver: j['driver'] as String? ?? '—',
  );
}
