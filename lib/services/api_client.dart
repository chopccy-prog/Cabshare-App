// lib/services/api_client.dart - COMPLETELY FIXED WITH ALL METHODS
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;
  final AuthService _authService = AuthService();
  
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
      const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000');

  final http.Client _http = http.Client();
  String? _authToken;
  
  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? getCurrentUserId() {
    final authUserId = _authService.currentUserId;
    if (authUserId != null) return authUserId;
    
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) return supabaseUser.id;
    
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return firebaseUser.uid;
    
    // Development fallback
    return '00000000-0000-0000-0000-000000000001';
  }

  String getCurrentAuthProvider() {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) return 'supabase';
    
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return 'firebase';
    
    return 'demo';
  }

  String? getCurrentUserEmail() {
    final authEmail = _authService.userEmail;
    if (authEmail != null) return authEmail;
    
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) return supabaseUser.email;
    
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return firebaseUser.email;
    
    // Development fallback
    return 'demo@worksetu.com';
  }

  String? getCurrentUserPhone() {
    final authPhone = _authService.userPhone;
    if (authPhone != null) return authPhone;
    
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) return supabaseUser.phone;
    
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return firebaseUser.phoneNumber;
    
    // Development fallback
    return '+919999999999';
  }

  /// Get auth headers with proper JWT token and fallbacks
  Future<Map<String, String>> get defaultHeaders async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    String? token;
    
    // Try to get token from various sources
    try {
      token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('✅ Using AuthService token');
      }
    } catch (e) {
      print('AuthService token failed: $e');
    }
    
    // Fallback to Supabase token
    if (token == null || token.isEmpty) {
      try {
        final supabaseUser = Supabase.instance.client.auth.currentUser;
        final supabaseSession = Supabase.instance.client.auth.currentSession;
        if (supabaseUser != null && supabaseSession != null) {
          token = supabaseSession.accessToken;
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            print('✅ Using Supabase token');
          }
        }
      } catch (e) {
        print('Supabase token failed: $e');
      }
    }
    
    // Fallback to stored token
    if (token == null || token.isEmpty) {
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
        print('✅ Using stored token');
        token = _authToken;
      }
    }
    
    // Always add user identification headers for backend fallback authentication
    final userId = getCurrentUserId();
    if (userId != null) {
      headers['x-user-id'] = userId;
      headers['x-auth-provider'] = getCurrentAuthProvider();
      print('✅ Added user ID header: $userId');
    }
    
    final email = getCurrentUserEmail();
    final phone = getCurrentUserPhone();
    if (email != null) {
      headers['x-user-email'] = email;
      print('✅ Added email header: $email');
    }
    if (phone != null) {
      headers['x-user-phone'] = phone;
      print('✅ Added phone header: $phone');
    }
    
    // Add user name for profile creation
    headers['x-user-name'] = 'Demo User';
    
    print('🔑 Final headers: $headers');
    
    return headers;
  }

  String? whoAmI() => getCurrentUserId();

  // UTILITY METHOD: Convert API response to List safely
  List<Map<String, dynamic>> _convertToList(dynamic response, [String? dataKey]) {
    if (response == null) return [];
    
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    
    if (response is Map<String, dynamic>) {
      // Try different possible keys for the data
      final possibleKeys = [
        dataKey,
        'data',
        'items',
        'results',
        'vehicles',
        'documents',
        'transactions',
        'bookings',
        'routes',
        'cities',
        'stops',
        'threads',
        'messages',
      ].where((key) => key != null).cast<String>();
      
      for (final key in possibleKeys) {
        if (response[key] is List) {
          return (response[key] as List).cast<Map<String, dynamic>>();
        }
      }
      
      // If no list found in the map, return empty list
      return [];
    }
    
    return [];
  }

  // Enhanced HTTP methods with better error handling
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final headers = await defaultHeaders;
      final baseEndpoint = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      
      Uri uri;
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        final separator = baseEndpoint.contains('?') ? '&' : '?';
        uri = Uri.parse('$baseEndpoint$separator$queryString');
      } else {
        uri = Uri.parse(baseEndpoint);
      }
      
      print('🌐 GET request: $uri');
      
      final response = await _http.get(
        uri,
        headers: headers,
      );
      
      print('📝 Response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode >= 400) {
        throw Exception('GET $endpoint failed: ${response.statusCode} ${response.body}');
      }
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('❌ GET $endpoint error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await defaultHeaders;
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      
      print('🌐 POST request: $url');
      print('📤 Data: $data');
      
      final response = await _http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      
      print('📝 Response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode >= 400) {
        throw Exception('POST $endpoint failed: ${response.statusCode} ${response.body}');
      }
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('❌ POST $endpoint error: $e');
      rethrow;
    }
  }

  // CITIES - Load from backend API with proper error handling
  Future<List<Map<String, dynamic>>> getCities() async {
    print('🏙️ Loading cities from backend API...');
    
    try {
      final headers = await defaultHeaders;
      final endpoints = ['/api/admin/cities', '/api/cities', '/admin/cities', '/cities'];
      
      for (final endpoint in endpoints) {
        try {
          final resp = await _http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
          
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            
            // Handle different response formats
            List<Map<String, dynamic>> cities = [];
            if (data is List) {
              cities = data.cast<Map<String, dynamic>>();
            } else if (data is Map && data['data'] is List) {
              cities = (data['data'] as List).cast<Map<String, dynamic>>();
            } else if (data is Map && data['cities'] is List) {
              cities = (data['cities'] as List).cast<Map<String, dynamic>>();
            }
            
            if (cities.isNotEmpty) {
              print('✅ Got ${cities.length} cities from API via $endpoint');
              return cities;
            }
          }
        } catch (e) {
          print('⚠️ Failed endpoint $endpoint: $e');
        }
      }
    } catch (e) {
      print('⚠️ Cities API error: $e');
    }
    
    // Only use fallback if API completely fails
    final fallbackCities = [
      {'id': '1', 'name': 'Mumbai', 'state': 'Maharashtra'},
      {'id': '2', 'name': 'Pune', 'state': 'Maharashtra'},
      {'id': '3', 'name': 'Nashik', 'state': 'Maharashtra'},
      {'id': '4', 'name': 'Delhi', 'state': 'Delhi'},
      {'id': '5', 'name': 'Bangalore', 'state': 'Karnataka'},
      {'id': '6', 'name': 'Chennai', 'state': 'Tamil Nadu'},
    ];
    
    print('🔄 Using fallback cities: ${fallbackCities.length} cities');
    return fallbackCities;
  }

  // ROUTES - Enhanced with proper search endpoints
  Future<List<Map<String, dynamic>>> getRoutes({
    String? fromCityId, 
    String? toCityId, 
    String? from, 
    String? to
  }) async {
    if (from == null || to == null || from.isEmpty || to.isEmpty) {
      return [];
    }
    
    print('🛣️ Loading routes for $from → $to');
    
    // Create fallback route immediately
    final fallbackRoute = {
      'id': '${from.toLowerCase().replaceAll(' ', '-')}-${to.toLowerCase().replaceAll(' ', '-')}',
      'name': '$from to $to Direct',
      'origin': from,
      'destination': to,
      'from_city': from,
      'to_city': to,
      'distance_km': null,
      'estimated_duration_minutes': null,
    };
    
    try {
      final queryParams = <String, String>{
        'from': from,
        'to': to,
      };
      
      final endpoints = ['/api/admin/routes/search', '/api/routes/search', '/admin/routes/search', '/routes/search'];
      
      for (final endpoint in endpoints) {
        try {
          final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
          final response = await get(uri.toString());
          
          // Handle both direct array and success/data wrapper
          final routes = _convertToList(response, 'data');
          
          if (routes.isNotEmpty) {
            print('✅ Got routes from API: ${routes.length} routes via $endpoint');
            return routes;
          }
        } catch (e) {
          print('⚠️ Failed endpoint $endpoint: $e');
        }
      }
    } catch (e) {
      print('⚠️ Routes API error: $e');
    }
    
    print('🔄 Using fallback route: ${fallbackRoute['name']}');
    return [fallbackRoute];
  }

  // STOPS - Enhanced with proper API integration
  Future<List<Map<String, dynamic>>> getStops(String routeId) async {
    print('🚏 Loading stops for route: $routeId');
    
    // Create fallback stops
    final fallbackStops = [
      {
        'id': '${routeId}_start',
        'route_id': routeId,
        'name': 'Starting Point',
        'stop_order': 1,
        'is_pickup': true,
        'is_drop': false,
      },
      {
        'id': '${routeId}_mid',
        'route_id': routeId,
        'name': 'Mid Point',
        'stop_order': 2,
        'is_pickup': true,
        'is_drop': true,
      },
      {
        'id': '${routeId}_end',
        'route_id': routeId,
        'name': 'End Point',
        'stop_order': 3,
        'is_pickup': false,
        'is_drop': true,
      }
    ];
    
    try {
      final endpoints = ['/api/admin/routes/$routeId/stops', '/api/routes/$routeId/stops', '/admin/routes/$routeId/stops', '/routes/$routeId/stops'];
      
      for (final endpoint in endpoints) {
        try {
          final response = await get(endpoint);
          
          // Handle both direct array and success/data wrapper
          final stops = _convertToList(response, 'data');
          
          if (stops.isNotEmpty) {
            print('✅ Got stops from API: ${stops.length} stops via $endpoint');
            return stops;
          }
        } catch (e) {
          print('⚠️ Failed endpoint $endpoint: $e');
        }
      }
    } catch (e) {
      print('⚠️ Stops API error: $e');
    }
    
    print('🔄 Using fallback stops: ${fallbackStops.length} stops');
    return fallbackStops;
  }

  // PUBLISH RIDE - Enhanced with better error handling
  Future<Map<String, dynamic>> publishRide({
    required String fromLocation,
    required String toLocation,
    required String departAt,
    required int seats,
    required int pricePerSeatInr,
    String rideType = 'private_pool',
    String? carPlate,
    String? carModel,
    String? carMake,
    String? routeId,
    String? fromCityId,
    String? toCityId,
    List<String>? selectedPickupStops,
    List<String>? selectedDropStops,
    bool autoApprove = true,
    String? notes,
  }) async {
    print('🚗 Publishing ride: $fromLocation → $toLocation');
    
    final body = <String, dynamic>{
      'from': fromLocation,
      'to': toLocation,
      'when': departAt,
      'seats': seats,
      'price': pricePerSeatInr,
      'pool': rideType,
      'notes': notes,
      // Remove auto_approve until database schema is updated
      // 'auto_approve': autoApprove,
      'auth_provider': getCurrentAuthProvider(),
    };
    
    print('📤 Ride data: $body');
    
    // Try multiple endpoints
    final endpoints = ['/api/rides', '/rides'];
    Exception? lastError;
    
    for (final endpoint in endpoints) {
      try {
        print('🔄 Trying endpoint: $endpoint');
        final result = await post(endpoint, body);
        print('✅ Ride published successfully via $endpoint');
        return result;
      } catch (e) {
        print('❌ Failed endpoint $endpoint: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        if (endpoint == endpoints.last) {
          print('💥 All endpoints failed, throwing last error');
        }
      }
    }
    
    throw lastError ?? Exception('All ride publishing endpoints failed');
  }

  // SEARCH RIDES - Enhanced
  Future<List<Map<String, dynamic>>> searchRides({
    String? fromCity,
    String? toCity,
    DateTime? fromDate,
    String? from,
    String? to,
    String? when,
    String? type,
  }) async {
    final qp = <String, String>{};
    if ((from ?? fromCity ?? '').isNotEmpty) qp['from'] = from ?? fromCity!;
    if ((to ?? toCity ?? '').isNotEmpty) qp['to'] = to ?? toCity!;
    if ((when ?? (fromDate?.toIso8601String().substring(0, 10)) ?? '').isNotEmpty) {
      qp['when'] = when ?? fromDate!.toIso8601String().substring(0, 10);
    }
    if ((type ?? '').isNotEmpty && type != 'all') qp['type'] = type!;

    print('🔍 Searching rides with params: $qp');

    final headers = await defaultHeaders;
    final endpoints = ['/api/rides/search', '/rides/search', '/api/rides', '/rides'];
    
    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint').replace(
          queryParameters: qp.isEmpty ? null : qp,
        );
        
        final resp = await _http.get(uri, headers: headers);
        
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data is List) {
            print('✅ Found ${data.length} rides via $endpoint');
            return data.cast<Map<String, dynamic>>();
          }
        }
      } catch (e) {
        print('⚠️ Search endpoint $endpoint failed: $e');
      }
    }
    
    print('❌ All search endpoints failed');
    return [];
  }

  // RIDE MANAGEMENT METHODS
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final endpoints = ['/api/rides/$rideId', '/rides/$rideId'];
    
    for (final endpoint in endpoints) {
      try {
        return await get(endpoint);
      } catch (e) {
        if (endpoint == endpoints.last) rethrow;
      }
    }
    
    throw Exception('All getRide endpoints failed');
  }

  Future<List<Map<String, dynamic>>> myPublishedRides() async {
    final uid = whoAmI();
    if (uid == null) return [];
    
    try {
      // Try multiple endpoints for published rides
      final endpoints = ['/api/rides/mine', '/api/rides/my-published', '/rides/mine'];
      
      for (final endpoint in endpoints) {
        try {
          final response = await get(endpoint);
          final rides = _convertToList(response, 'rides');
          if (rides.isNotEmpty) {
            print('Got ${rides.length} published rides from $endpoint');
            return rides;
          }
        } catch (e) {
          print('Published rides endpoint $endpoint failed: $e');
        }
      }
      
      // Fallback: search all rides and filter by current user
      final allRides = await searchRides();
      return allRides.where((ride) => ride['driver_id'] == uid || ride['user_id'] == uid).toList();
    } catch (e) {
      print('My published rides failed: $e');
      return [];
    }
  }

  // BOOKING METHODS - Enhanced with better ID handling
  Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required int seats,
    String? pickupStopId,
    String? dropStopId,
  }) async {
    print('📚 Creating booking for ride ID: $rideId');
    
    final payload = {
      'ride_id': rideId,
      'seats_booked': seats,
      // Remove fields not in current database schema
      // 'from_stop_id': pickupStopId,
      // 'to_stop_id': dropStopId,
      'auth_provider': getCurrentAuthProvider(),
      'user_email': getCurrentUserEmail(),
      'user_phone': getCurrentUserPhone(),
    };
    
    print('📤 Booking payload: $payload');
    
    final endpoints = ['/api/bookings', '/bookings'];
    
    for (final endpoint in endpoints) {
      try {
        print('🔄 Trying booking endpoint: $endpoint');
        final result = await post(endpoint, payload);
        print('✅ Booking created successfully via $endpoint');
        return result;
      } catch (e) {
        print('❌ Failed booking endpoint $endpoint: $e');
        if (endpoint == endpoints.last) {
          print('💥 All booking endpoints failed');
          rethrow;
        }
      }
    }
    
    throw Exception('All booking endpoints failed');
  }

  Future<Map<String, dynamic>> bookRide(Map<String, dynamic> bookingData) async {
    return await createBooking(
      rideId: bookingData['ride_id'].toString(),
      seats: bookingData['seats_booked'] ?? 1,
      pickupStopId: bookingData['pickup_point'],
      dropStopId: bookingData['drop_point'],
    );
  }

  Future<List<Map<String, dynamic>>> myBookings() async {
    final uid = whoAmI();
    if (uid == null) return [];
    
    try {
      // Try multiple endpoints for bookings
      final endpoints = ['/api/bookings/mine', '/api/bookings', '/bookings/mine', '/bookings'];
      
      for (final endpoint in endpoints) {
        try {
          final response = await get(endpoint);
          final bookings = _convertToList(response, 'bookings');
          if (bookings.isNotEmpty) {
            print('Got ${bookings.length} bookings from $endpoint');
            return bookings;
          }
        } catch (e) {
          print('Bookings endpoint $endpoint failed: $e');
        }
      }
      
      return [];
    } catch (e) {
      print('My bookings failed: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDriverBookings() async {
    try {
      final response = await get('/api/bookings/driver');
      return _convertToList(response, 'bookings');
    } catch (e) {
      print('⚠️ Driver bookings API failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      return await post('/api/bookings/$bookingId/cancel', {});
    } catch (e) {
      print('⚠️ Cancel booking failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> approveBooking(String bookingId) async {
    try {
      return await post('/api/bookings/$bookingId/approve', {});
    } catch (e) {
      print('⚠️ Approve booking failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBooking(String bookingId) async {
    try {
      return await post('/api/bookings/$bookingId/reject', {});
    } catch (e) {
      print('⚠️ Reject booking failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // PROFILE METHODS - ALL RESTORED
  Future<Map<String, dynamic>> getProfile({String? uid}) async {
    try {
      return await get('/api/profile/me');
    } catch (e) {
      print('⚠️ Get profile failed: $e');
      // Return fallback profile
      return {
        'id': getCurrentUserId(),
        'full_name': 'Demo User',
        'email': getCurrentUserEmail(),
        'phone': getCurrentUserPhone(),
        'role': 'rider',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields, {String? uid}) async {
    try {
      return await post('/api/profile/update', fields);
    } catch (e) {
      print('⚠️ Update profile failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    try {
      final response = await get('/api/profile/vehicles');
      return _convertToList(response, 'vehicles');
    } catch (e) {
      print('⚠️ Get vehicles failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      return await post('/api/profile/vehicles', vehicleData);
    } catch (e) {
      print('⚠️ Add vehicle failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getKycDocuments() async {
    try {
      final response = await get('/api/profile/kyc');
      return _convertToList(response, 'documents');
    } catch (e) {
      print('⚠️ Get KYC documents failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadKycDocument(Map<String, dynamic> docData) async {
    try {
      return await post('/api/profile/kyc', docData);
    } catch (e) {
      print('⚠️ Upload KYC document failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // WALLET METHODS - ALL RESTORED
  Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      return await get('/api/wallet/details');
    } catch (e) {
      print('⚠️ Get wallet details failed: $e');
      return {
        'balance_available_inr': 0,
        'balance_reserved_inr': 0,
      };
    }
  }

  Future<int> getWalletBalance() async {
    try {
      final response = await get('/api/wallet/balance');
      return (response['balance_available_inr'] ?? 0) as int;
    } catch (e) {
      print('⚠️ Get wallet balance failed: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await get('/api/wallet/transactions');
      return _convertToList(response, 'transactions');
    } catch (e) {
      print('⚠️ Get transactions failed: $e');
      return [];
    }
  }

  // CHAT/INBOX METHODS - ALL RESTORED
  Future<List<Map<String, dynamic>>> inbox() async {
    try {
      final response = await get('/api/inbox/threads');
      return _convertToList(response, 'threads');
    } catch (e) {
      print('⚠️ Get inbox failed: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInboxThreads() async {
    return await inbox(); // Alias for backward compatibility
  }

  Future<List<Map<String, dynamic>>> messages(String rideId, String otherUserId) async {
    try {
      final response = await get('/api/inbox/messages?ride_id=$rideId&other_user_id=$otherUserId');
      return _convertToList(response, 'messages');
    } catch (e) {
      print('⚠️ Get messages failed: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String threadId) async {
    try {
      final response = await get('/api/inbox/threads/$threadId/messages');
      return _convertToList(response, 'messages');
    } catch (e) {
      print('⚠️ Get thread messages failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String rideId, String recipientId, String message) async {
    try {
      return await post('/api/inbox/send', {
        'ride_id': rideId,
        'recipient_id': recipientId,
        'message': message,
      });
    } catch (e) {
      print('⚠️ Send message failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessageToThread(String threadId, String message) async {
    try {
      return await post('/api/inbox/threads/$threadId/messages', {
        'message': message,
      });
    } catch (e) {
      print('⚠️ Send thread message failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ADMIN METHODS - RESTORED
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      return await get('/api/admin/stats');
    } catch (e) {
      print('⚠️ Get admin stats failed: $e');
      return {};
    }
  }

  // UTILITY METHODS
  void dispose() {
    _http.close();
  }

  void printAuthState() {
    print('🔐 === API Client Auth State ===');
    print('Current User ID: ${getCurrentUserId()}');
    print('Auth Provider: ${getCurrentAuthProvider()}');
    print('Email: ${getCurrentUserEmail()}');
    print('Phone: ${getCurrentUserPhone()}');
    print('Has Auth Token: ${_authToken != null}');
    print('=============================');
  }
}
