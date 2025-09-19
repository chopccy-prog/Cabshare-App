// lib/services/profile_repo.dart - Profile Repository Service
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';

class ProfileRepo {
  static String get _baseUrl => '${Config.apiBaseUrl}/api/profile';
  final AuthService _authService = AuthService();

  // Get user profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['profile'];
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Update/Insert profile
  Future<Map<String, dynamic>?> upsertMyProfile({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'full_name': fullName,
          'phone': phone,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['profile'];
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Get user vehicles
  Future<List<Map<String, dynamic>>> myVehicles() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  // Get KYC documents
  Future<List<Map<String, dynamic>>> myKycDocs() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/kyc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['documents'] ?? []);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching KYC documents: $e');
    }
  }

  // Upload KYC document
  Future<bool> uploadKycDoc({
    required String docType,
    required Uint8List fileData,
    required String fileName,
  }) async {
    try {
      final token = await _authService.getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/kyc/upload'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['doc_type'] = docType;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'document',
          fileData,
          filename: fileName,
        ),
      );

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error uploading KYC document: $e');
    }
  }

  // Add vehicle
  Future<bool> addVehicle({
    required String make,
    required String model,
    required String plateNumber,
    required String vehicleType,
    String? color,
    int? year,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/vehicles/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'make': make,
          'model': model,
          'plate_number': plateNumber,
          'vehicle_type': vehicleType,
          'color': color,
          'year': year,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  // Delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  // Verify phone with OTP
  Future<bool> verifyPhone(String otp) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error verifying phone: $e');
    }
  }

  // Start phone verification
  Future<bool> startPhoneVerification(String phone) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/start-phone-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error starting phone verification: $e');
    }
  }
}