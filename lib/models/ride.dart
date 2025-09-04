import 'package:supabase_flutter/supabase_flutter.dart';

class Ride {
  final String id;
  final String? driverId;
  final String? routeId;
  final DateTime? departDate;
  final String departTime;
  final int? pricePerSeatInr;
  final int? seatsTotal;
  final int? seatsAvailable;
  final String? carMake;
  final String? carModel;
  final String? carPlate;
  final String? notes;
  final String status;
  final bool allowAutoConfirm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fromCity;
  final String? toCity;

  Ride({
    required this.id,
    this.driverId,
    this.routeId,
    this.departDate,
    required this.departTime,
    this.pricePerSeatInr,
    this.seatsTotal,
    this.seatsAvailable,
    this.carMake,
    this.carModel,
    this.carPlate,
    this.notes,
    required this.status,
    required this.allowAutoConfirm,
    required this.createdAt,
    required this.updatedAt,
    this.fromCity,
    this.toCity,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String? ?? '',
      driverId: json['driver_id'] as String?,
      routeId: json['route_id'] as String?,
      departDate: json['depart_date'] != null ? DateTime.parse(json['depart_date']) : null,
      departTime: json['depart_time'] as String? ?? '',
      pricePerSeatInr: json['price_per_seat_inr'] as int?,
      seatsTotal: json['seats_total'] as int?,
      seatsAvailable: json['seats_available'] as int?,
      carMake: json['car_make'] as String?,
      carModel: json['car_model'] as String?,
      carPlate: json['car_plate'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'unknown',
      allowAutoConfirm: json['allow_auto_confirm'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      fromCity: json['from_city'] as String?,
      toCity: json['to_city'] as String?,
    );
  }
}