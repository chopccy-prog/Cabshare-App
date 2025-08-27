class Booking {
  final String id;
  final String rideId;
  final String passengerId;
  final int seats;
  final String status;
  final String createdAt;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seats,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: '${j['id']}',
    rideId: '${j['rideId']}',
    passengerId: '${j['passengerId']}',
    seats: (j['seats'] as num).toInt(),
    status: '${j['status']}',
    createdAt: '${j['createdAt']}',
  );
}
