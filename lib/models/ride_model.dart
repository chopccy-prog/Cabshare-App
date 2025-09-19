// lib/models/ride_model.dart - Enhanced version with all new features
class RideModel {
  final int id;
  final int driverId;
  final int? routeId;
  final int? pickupStopId;
  final int? dropStopId;
  final DateTime departDate;
  final String departTime;
  final double pricePerSeat;
  final int seatsAvailable;
  final int totalSeats;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehiclePlate;
  final String additionalNotes;
  final bool requiresDeposit;
  final double depositAmount;
  final bool autoApproveBookings;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Navigation properties (when fetched with joins)
  final String? driverName;
  final String? driverPhone;
  final String? routeName;
  final String? fromCity;
  final String? toCity;
  final String? pickupStopName;
  final String? dropStopName;

  RideModel({
    required this.id,
    required this.driverId,
    this.routeId,
    this.pickupStopId,
    this.dropStopId,
    required this.departDate,
    required this.departTime,
    required this.pricePerSeat,
    required this.seatsAvailable,
    required this.totalSeats,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.additionalNotes,
    required this.requiresDeposit,
    required this.depositAmount,
    required this.autoApproveBookings,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.driverName,
    this.driverPhone,
    this.routeName,
    this.fromCity,
    this.toCity,
    this.pickupStopName,
    this.dropStopName,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      routeId: json['route_id'] as int?,
      pickupStopId: json['pickup_stop_id'] as int?,
      dropStopId: json['drop_stop_id'] as int?,
      departDate: DateTime.parse(json['depart_date'] as String),
      departTime: json['depart_time'] as String,
      pricePerSeat: (json['price_per_seat_inr'] as num).toDouble(),
      seatsAvailable: json['seats_available'] as int,
      totalSeats: json['total_seats'] as int? ?? json['seats_available'] as int,
      vehicleType: json['vehicle_type'] as String,
      vehicleMake: json['vehicle_make'] as String,
      vehicleModel: json['vehicle_model'] as String,
      vehiclePlate: json['vehicle_plate'] as String,
      additionalNotes: json['additional_notes'] as String? ?? '',
      requiresDeposit: json['requires_deposit'] as bool? ?? false,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      autoApproveBookings: json['auto_approve_bookings'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      
      // Navigation properties (from joins)
      driverName: _getNestedValue(json, ['driver', 'full_name']),
      driverPhone: _getNestedValue(json, ['driver', 'phone']),
      routeName: _getNestedValue(json, ['route', 'name']),
      fromCity: json['from_city'] as String? ?? _getNestedValue(json, ['route', 'from_city']),
      toCity: json['to_city'] as String? ?? _getNestedValue(json, ['route', 'to_city']),
      pickupStopName: _getNestedValue(json, ['pickup_stop', 'name']),
      dropStopName: _getNestedValue(json, ['drop_stop', 'name']),
    );
  }

  static String? _getNestedValue(Map<String, dynamic> json, List<String> keys) {
    dynamic current = json;
    for (String key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'route_id': routeId,
      'pickup_stop_id': pickupStopId,
      'drop_stop_id': dropStopId,
      'depart_date': departDate.toIso8601String().split('T')[0],
      'depart_time': departTime,
      'price_per_seat_inr': pricePerSeat,
      'seats_available': seatsAvailable,
      'total_seats': totalSeats,
      'vehicle_type': vehicleType,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_plate': vehiclePlate,
      'additional_notes': additionalNotes,
      'requires_deposit': requiresDeposit,
      'deposit_amount': depositAmount,
      'auto_approve_bookings': autoApproveBookings,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get vehicleDisplayName => '$vehicleMake $vehicleModel';
  
  String get routeDisplayName => routeName ?? '$fromCity → $toCity';
  
  String get vehicleTypeDisplayName {
    switch (vehicleType) {
      case 'commercial_pool':
        return 'Commercial Pool';
      case 'commercial_full':
        return 'Commercial Full Booking';
      case 'private':
      default:
        return 'Private Car';
    }
  }

  bool get isCommercial => vehicleType.startsWith('commercial');
  
  bool get isPrivate => vehicleType == 'private';
  
  bool get hasAvailableSeats => seatsAvailable > 0;
  
  DateTime get departureDateTime {
    final timeParts = departTime.split(':');
    return DateTime(
      departDate.year,
      departDate.month,
      departDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
    );
  }

  bool get isPast {
    return departureDateTime.isBefore(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return departDate.year == now.year &&
           departDate.month == now.month &&
           departDate.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return departDate.year == tomorrow.year &&
           departDate.month == tomorrow.month &&
           departDate.day == tomorrow.day;
  }

  String get departureDateDisplay {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return '${departDate.day}/${departDate.month}';
  }

  double get hoursUntilDeparture {
    final now = DateTime.now();
    final departure = departureDateTime;
    return departure.difference(now).inMinutes / 60.0;
  }

  bool get canBeCancelled {
    return !isPast && status == 'active';
  }

  @override
  String toString() {
    return 'RideModel(id: $id, route: $routeDisplayName, vehicle: $vehicleDisplayName, price: ₹$pricePerSeat, seats: $seatsAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
