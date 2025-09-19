// lib/models/booking_model.dart
// UPDATED FOR DATABASE CLEANUP - Uses consolidated column names

import 'ride.dart';

class Booking {
  final String id;
  final String rideId;
  final String riderId;
  final String fromStopId;
  final String toStopId;
  final int seatsBooked;           // Updated: unified from seats_requested, seats
  final double fareTotalInr;       // Updated: from fare_total_inr
  final double riderDepositInr;    // Updated: from deposit_inr
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? depositStatus;
  final bool requiresDeposit;
  
  // Related data
  final Ride? ride;
  final Stop? fromStop;
  final Stop? toStop;
  final List<Cancellation>? cancellations;

  Booking({
    required this.id,
    required this.rideId,
    required this.riderId,
    required this.fromStopId,
    required this.toStopId,
    required this.seatsBooked,
    required this.fareTotalInr,
    required this.riderDepositInr,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.depositStatus,
    this.requiresDeposit = false,
    this.ride,
    this.fromStop,
    this.toStop,
    this.cancellations,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      rideId: json['ride_id'],
      riderId: json['rider_id'],
      fromStopId: json['from_stop_id'],
      toStopId: json['to_stop_id'],
      seatsBooked: json['seats_booked'] ?? 1,
      fareTotalInr: (json['fare_total_inr'] ?? 0).toDouble(),
      riderDepositInr: (json['rider_deposit_inr'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      depositStatus: json['deposit_status'],
      requiresDeposit: json['requires_deposit'] ?? false,
      ride: json['rides'] != null ? Ride.fromJson(json['rides']) : null,
      fromStop: json['from_stop'] != null ? Stop.fromJson(json['from_stop']) : null,
      toStop: json['to_stop'] != null ? Stop.fromJson(json['to_stop']) : null,
      cancellations: json['cancellations'] != null 
          ? (json['cancellations'] as List)
              .map((c) => Cancellation.fromJson(c))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'rider_id': riderId,
      'from_stop_id': fromStopId,
      'to_stop_id': toStopId,
      'seats_booked': seatsBooked,
      'fare_total_inr': fareTotalInr,
      'rider_deposit_inr': riderDepositInr,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deposit_status': depositStatus,
      'requires_deposit': requiresDeposit,
    };
  }

  // Backward compatibility getters
  double get fareTotal => fareTotalInr;
  double get deposit => riderDepositInr;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  double get totalAmount => fareTotalInr + riderDepositInr;

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  String get routeDisplayText {
    if (fromStop != null && toStop != null) {
      return '${fromStop!.name} → ${toStop!.name}';
    }
    return '$fromStopId → $toStopId';
  }
}

class Stop {
  final String id;
  final String name;
  final String? cityName;        // Updated: from 'city' to 'city_name'
  final double? latitude;        // Updated: from 'lat'
  final double? longitude;       // Updated: from 'lon'
  final String? address;
  final int? stopOrder;
  final bool? isPickup;
  final bool? isDrop;
  final bool? isActive;

  Stop({
    required this.id,
    required this.name,
    this.cityName,
    this.latitude,
    this.longitude,
    this.address,
    this.stopOrder,
    this.isPickup,
    this.isDrop,
    this.isActive,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: json['name'],
      cityName: json['city_name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      stopOrder: json['stop_order'],
      isPickup: json['is_pickup'],
      isDrop: json['is_drop'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city_name': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'stop_order': stopOrder,
      'is_pickup': isPickup,
      'is_drop': isDrop,
      'is_active': isActive,
    };
  }

  // Backward compatibility
  String? get city => cityName;
  double? get lat => latitude;
  double? get lon => longitude;
}

class Cancellation {
  final String id;
  final String bookingId;
  final String cancelledBy;
  final DateTime cancelledAt;
  final double? hoursBeforeDepart;
  final double penaltyAmount;
  final String? note;

  Cancellation({
    required this.id,
    required this.bookingId,
    required this.cancelledBy,
    required this.cancelledAt,
    this.hoursBeforeDepart,
    required this.penaltyAmount,
    this.note,
  });

  factory Cancellation.fromJson(Map<String, dynamic> json) {
    return Cancellation(
      id: json['id'],
      bookingId: json['booking_id'],
      cancelledBy: json['cancelled_by'],
      cancelledAt: DateTime.parse(json['cancelled_at']),
      hoursBeforeDepart: json['hours_before_depart']?.toDouble(),
      penaltyAmount: (json['penalty_inr'] ?? 0).toDouble(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'cancelled_by': cancelledBy,
      'cancelled_at': cancelledAt.toIso8601String(),
      'hours_before_depart': hoursBeforeDepart,
      'penalty_inr': penaltyAmount,
      'note': note,
    };
  }

  String get cancelledByDisplayText {
    switch (cancelledBy) {
      case 'rider':
        return 'Rider';
      case 'driver':
        return 'Driver';
      case 'system':
        return 'System';
      default:
        return cancelledBy;
    }
  }
}
