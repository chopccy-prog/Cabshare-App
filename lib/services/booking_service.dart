import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import '../models/booking_model.dart';

class BookingService {
  static String get _baseUrl => '${Config.apiBaseUrl}/api/bookings';
  final AuthService _authService = AuthService();

  // Create new booking with deposit
  Future<BookingResult> createBooking({
    required String rideId,
    required String fromStop,
    required String toStop,
    required int seatsRequested,
    required double fareAmount,
    required double depositAmount,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rideId': rideId,
          'fromStopId': fromStop,
          'toStopId': toStop,
          'seatsRequested': seatsRequested,
          'fareAmount': fareAmount,
          'depositAmount': depositAmount,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return BookingResult(
          success: true,
          bookingId: data['bookingId'],
          status: data['status'],
          message: data['message'],
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'] ?? 'Booking failed',
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Error creating booking: $e',
      );
    }
  }

  // Get booking details
  Future<Booking?> getBookingDetails(String bookingId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Booking.fromJson(data['booking']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching booking details: $e');
    }
  }

  // Cancel booking
  Future<CancellationResult> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reason': reason ?? 'User cancellation',
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return CancellationResult(
          success: true,
          message: data['message'],
          penaltyAmount: (data['penaltyAmount'] ?? 0).toDouble(),
          refundAmount: (data['refundAmount'] ?? 0).toDouble(),
        );
      } else {
        return CancellationResult(
          success: false,
          message: data['message'] ?? 'Cancellation failed',
        );
      }
    } catch (e) {
      return CancellationResult(
        success: false,
        message: 'Error cancelling booking: $e',
      );
    }
  }

  // Get user's bookings
  Future<List<Booking>> getUserBookings({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      
      String url = '$_baseUrl/user/my-bookings?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['bookings'] as List)
              .map((booking) => Booking.fromJson(booking))
              .toList();
        }
      }
      throw Exception('Failed to get user bookings');
    } catch (e) {
      throw Exception('Error fetching user bookings: $e');
    }
  }

  // Get driver's booking requests
  Future<List<Booking>> getDriverBookings({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      
      String url = '$_baseUrl/driver/requests?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['bookings'] as List)
              .map((booking) => Booking.fromJson(booking))
              .toList();
        }
      }
      throw Exception('Failed to get driver bookings');
    } catch (e) {
      throw Exception('Error fetching driver bookings: $e');
    }
  }

  // Approve/Reject booking (for drivers)
  Future<bool> updateBookingStatus(String bookingId, String status, {String? note}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'note': note,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error updating booking status: $e');
    }
  }

  // Get cancellation policy for ride type
  Future<CancellationPolicy?> getCancellationPolicy(String rideType) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/policy/$rideType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CancellationPolicy.fromJson(data['policy']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching cancellation policy: $e');
    }
  }

  // Get cancellation penalty preview
  Future<CancellationPreview?> getCancellationPreview(String bookingId, {String cancelledBy = 'rider'}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/$bookingId/cancellation-preview?cancelledBy=$cancelledBy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CancellationPreview.fromJson(data['preview']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching cancellation preview: $e');
    }
  }
}

// Result classes
class BookingResult {
  final bool success;
  final String? bookingId;
  final String? status;
  final String message;

  BookingResult({
    required this.success,
    this.bookingId,
    this.status,
    required this.message,
  });
}

class CancellationResult {
  final bool success;
  final String message;
  final double penaltyAmount;
  final double refundAmount;

  CancellationResult({
    required this.success,
    required this.message,
    this.penaltyAmount = 0.0,
    this.refundAmount = 0.0,
  });
}

class CancellationPolicy {
  final String rideType;
  final String actor;
  final int tier1Hours;
  final double tier1PenaltyPct;
  final int tier2Hours;
  final double tier2PenaltyPct;
  final int tier3Hours;
  final double tier3PenaltyPct;

  CancellationPolicy({
    required this.rideType,
    required this.actor,
    required this.tier1Hours,
    required this.tier1PenaltyPct,
    required this.tier2Hours,
    required this.tier2PenaltyPct,
    required this.tier3Hours,
    required this.tier3PenaltyPct,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      rideType: json['ride_type'] ?? 'private_pool',
      actor: json['actor'] ?? 'rider',
      tier1Hours: json['tier_1_hours'] ?? 12,
      tier1PenaltyPct: (json['tier_1_penalty_pct'] ?? 0).toDouble(),
      tier2Hours: json['tier_2_hours'] ?? 6,
      tier2PenaltyPct: (json['tier_2_penalty_pct'] ?? 30).toDouble(),
      tier3Hours: json['tier_3_hours'] ?? 0,
      tier3PenaltyPct: (json['tier_3_penalty_pct'] ?? 50).toDouble(),
    );
  }

  String getFormattedPolicy() {
    return '''Cancellation Policy:
• ${tier1Hours}+ hours: ${tier1PenaltyPct}% penalty
• ${tier2Hours}-${tier1Hours} hours: ${tier2PenaltyPct}% penalty
• 0-${tier2Hours} hours: ${tier3PenaltyPct}% penalty''';
  }
}

class CancellationPreview {
  final double hoursBeforeDeparture;
  final double penaltyPercentage;
  final double penaltyAmount;
  final double refundAmount;
  final double totalPaid;

  CancellationPreview({
    required this.hoursBeforeDeparture,
    required this.penaltyPercentage,
    required this.penaltyAmount,
    required this.refundAmount,
    required this.totalPaid,
  });

  factory CancellationPreview.fromJson(Map<String, dynamic> json) {
    return CancellationPreview(
      hoursBeforeDeparture: (json['hours_before_departure'] ?? 0).toDouble(),
      penaltyPercentage: (json['penalty_percentage'] ?? 0).toDouble(),
      penaltyAmount: (json['penalty_amount'] ?? 0).toDouble(),
      refundAmount: (json['refund_amount'] ?? 0).toDouble(),
      totalPaid: (json['total_paid'] ?? 0).toDouble(),
    );
  }
}
