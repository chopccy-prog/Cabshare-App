import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';

class WalletService {
  static String get _baseUrl => '${Config.apiBaseUrl}/api/wallet';
  final AuthService _authService = AuthService();

  // Get wallet balance
  Future<double> getWalletBalance() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['balance']['available'] ?? 0).toDouble();
        }
      }
      throw Exception('Failed to get wallet balance');
    } catch (e) {
      throw Exception('Error fetching wallet balance: $e');
    }
  }

  // Get wallet details (available + reserved)
  Future<WalletDetails> getWalletDetails() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return WalletDetails.fromJson(data['wallet']);
        }
      }
      throw Exception('Failed to get wallet details');
    } catch (e) {
      throw Exception('Error fetching wallet details: $e');
    }
  }

  // Create deposit intent (Razorpay integration)
  Future<DepositIntent> createDepositIntent(double amount) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/deposit/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'method': 'razorpay',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return DepositIntent.fromJson(data['intent']);
        }
      }
      throw Exception('Failed to create deposit intent');
    } catch (e) {
      throw Exception('Error creating deposit intent: $e');
    }
  }

  // Verify payment and update wallet
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/deposit/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  // Get wallet transactions
  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['transactions'] as List)
              .map((tx) => WalletTransaction.fromJson(tx))
              .toList();
        }
      }
      throw Exception('Failed to get transactions');
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Request withdrawal/settlement
  Future<bool> requestSettlement(double amount) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/settlement/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error requesting settlement: $e');
    }
  }
}

// Models for wallet data
class WalletDetails {
  final double availableBalance;
  final double reservedBalance;
  final double totalBalance;
  final DateTime updatedAt;

  WalletDetails({
    required this.availableBalance,
    required this.reservedBalance,
    required this.totalBalance,
    required this.updatedAt,
  });

  factory WalletDetails.fromJson(Map<String, dynamic> json) {
    return WalletDetails(
      availableBalance: (json['balance_available_inr'] ?? 0).toDouble(),
      reservedBalance: (json['balance_reserved_inr'] ?? 0).toDouble(),
      totalBalance: (json['balance_available_inr'] ?? 0).toDouble() + 
                   (json['balance_reserved_inr'] ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class DepositIntent {
  final String id;
  final double amount;
  final String razorpayOrderId;
  final String status;

  DepositIntent({
    required this.id,
    required this.amount,
    required this.razorpayOrderId,
    required this.status,
  });

  factory DepositIntent.fromJson(Map<String, dynamic> json) {
    return DepositIntent(
      id: json['id'],
      amount: (json['amount_inr'] ?? 0).toDouble(),
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      status: json['status'] ?? 'created',
    );
  }
}

class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String? note;
  final String? refBookingId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.note,
    this.refBookingId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      type: json['tx_type'] ?? 'unknown',
      amount: (json['amount_inr'] ?? 0).toDouble(),
      note: json['note'],
      refBookingId: json['ref_booking_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayType {
    switch (type) {
      case 'reserve':
        return 'Reserved';
      case 'release':
        return 'Released';
      case 'transfer_in':
        return 'Credit';
      case 'transfer_out':
        return 'Debit';
      case 'adjustment':
        return 'Adjustment';
      default:
        return 'Transaction';
    }
  }

  bool get isCredit {
    return ['transfer_in', 'release'].contains(type);
  }
}
