// lib/models/ride.dart - RESTORED ORIGINAL WORKING VERSION
// This is the main model that works with both old and new field names

class Ride {
  final String id;
  final String? fromCityId;        // Database field
  final String? toCityId;          // Database field
  final String? fromCityName;      // For display
  final String? toCityName;        // For display
  final DateTime? departDate;      // Database field
  final String? departTime;        // Database field  
  final int seatsTotal;            // Database field
  final int seatsAvailable;        // Database field
  final num pricePerSeatInr;       // Database field
  final String? driverName;
  final String? driverPhone;
  final String? driverId;
  final bool booked;
  final String rideType;           // Database field
  final String? carMake;
  final String? carModel;
  final String? carPlate;
  final String? notes;
  final bool allowAutoConfirm;     // Database field
  final String status;

  Ride({
    required this.id,
    this.fromCityId,
    this.toCityId,
    this.fromCityName,
    this.toCityName,
    this.departDate,
    this.departTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeatInr,
    this.driverName,
    this.driverPhone,
    this.driverId,
    required this.booked,
    required this.rideType,
    this.carMake,
    this.carModel,
    this.carPlate,
    this.notes,
    this.allowAutoConfirm = false,
    this.status = 'published',
  });

  // Factory constructor with full backward compatibility
  factory Ride.fromJson(Map<String, dynamic> json) {
    // Parse date safely
    DateTime? parsedDate;
    try {
      if (json['depart_date'] != null) {
        parsedDate = DateTime.parse(json['depart_date']);
      } else if (json['when'] != null) {
        // Handle legacy 'when' field
        final whenStr = json['when'].toString();
        if (whenStr.contains(' ')) {
          parsedDate = DateTime.parse(whenStr.split(' ')[0]);
        } else {
          parsedDate = DateTime.parse(whenStr);
        }
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    // Extract time
    String? timeStr;
    try {
      if (json['depart_time'] != null) {
        timeStr = json['depart_time'].toString();
      } else if (json['when'] != null) {
        final whenStr = json['when'].toString();
        if (whenStr.contains(' ') && whenStr.split(' ').length >= 2) {
          timeStr = whenStr.split(' ')[1];
        }
      }
    } catch (e) {
      timeStr = null;
    }

    return Ride(
      id: (json['id'] ?? '').toString(),
      fromCityId: json['from_city_id']?.toString(),
      toCityId: json['to_city_id']?.toString(),
      fromCityName: json['from_city_name']?.toString() ?? 
                    json['fromCity']?.toString() ?? 
                    json['from']?.toString() ??
                    json['origin']?.toString(),
      toCityName: json['to_city_name']?.toString() ?? 
                  json['toCity']?.toString() ?? 
                  json['to']?.toString() ??
                  json['destination']?.toString(),
      departDate: parsedDate,
      departTime: timeStr,
      seatsTotal: int.tryParse(json['seats_total']?.toString() ?? 
                              json['seats']?.toString() ?? '0') ?? 0,
      seatsAvailable: int.tryParse(json['seats_available']?.toString() ?? 
                                  json['seats']?.toString() ?? '0') ?? 0,
      pricePerSeatInr: num.tryParse(json['price_per_seat_inr']?.toString() ?? 
                                   json['price']?.toString() ?? 
                                   json['price_inr']?.toString() ?? '0') ?? 0,
      driverName: json['driver_name']?.toString() ?? json['driverName']?.toString(),
      driverPhone: json['driver_phone']?.toString() ?? json['driverPhone']?.toString(),
      driverId: json['driver_id']?.toString(),
      booked: (json['booked'] is bool) ? json['booked'] as bool : false,
      rideType: json['ride_type']?.toString() ?? 
                json['pool']?.toString() ?? 
                'private_pool',
      carMake: json['car_make']?.toString(),
      carModel: json['car_model']?.toString(),
      carPlate: json['car_plate']?.toString(),
      notes: json['notes']?.toString(),
      allowAutoConfirm: (json['allow_auto_confirm'] is bool) ? 
                        json['allow_auto_confirm'] as bool : 
                        (json['auto_approve'] is bool) ? 
                        json['auto_approve'] as bool : false,
      status: json['status']?.toString() ?? 'published',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_city_id': fromCityId,
      'to_city_id': toCityId,
      'depart_date': departDate?.toIso8601String().split('T')[0],
      'depart_time': departTime,
      'seats_total': seatsTotal,
      'seats_available': seatsAvailable,
      'price_per_seat_inr': pricePerSeatInr,
      'driver_id': driverId,
      'booked': booked,
      'ride_type': rideType,
      'car_make': carMake,
      'car_model': carModel,
      'car_plate': carPlate,
      'notes': notes,
      'allow_auto_confirm': allowAutoConfirm,
      'status': status,
    };
  }

  // Legacy compatibility getters
  String get from => fromCityName ?? '';
  String get to => toCityName ?? '';
  String get fromCity => fromCityName ?? '';
  String get toCity => toCityName ?? '';
  DateTime get when => departDate ?? DateTime.now();
  int get seats => seatsAvailable; // Use available seats
  num get price => pricePerSeatInr;
  String get pool => rideType;
  bool get autoApprove => allowAutoConfirm;
  
  // Combined datetime for legacy 'when' field
  String get whenFormatted {
    if (departDate == null) return '';
    final dateStr = departDate!.toIso8601String().split('T')[0];
    final timeStr = departTime ?? '00:00:00';
    return '$dateStr $timeStr';
  }

  // Display methods
  String get prettyDate {
    if (departDate == null) return 'TBD';
    final date = departDate!;
    return '${date.day}/${date.month}/${date.year} at ${departTime ?? 'TBD'}';
  }

  String get formattedPrice => '₹${pricePerSeatInr.toStringAsFixed(0)}';
  String get formattedRoute => '${fromCityName ?? 'Unknown'} → ${toCityName ?? 'Unknown'}';
  
  String get formattedDateTime {
    if (departDate == null) return 'TBD';
    return '${departDate!.day}/${departDate!.month} at ${departTime ?? ''}';
  }

  // Static method for parsing list from JSON (used by some old code)
  static List<Ride> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => Ride.fromJson(json as Map<String, dynamic>)).toList();
  }
}
