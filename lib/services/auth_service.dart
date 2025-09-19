// lib/services/auth_service.dart - FIXED ALL DUPLICATE METHODS
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  final _firebase = fb.FirebaseAuth.instance;
  final String _apiBaseUrl = '${Env.apiBase}/api';

  Map<String, dynamic>? _currentUser;
  String? _jwtToken;
  String? _pendingPhoneVerification;
  Map<String, dynamic>? _pendingPhoneLink;
  bool _listenersInitialized = false;

  // Stream controllers for backward compatibility
  final _signedInController = StreamController<bool>.broadcast();

  // Current user getters
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?['id'];
  bool get isLoggedIn => _currentUser != null;
  String? get jwtToken => _jwtToken;

  // FIXED: Consolidated getters - no duplicates
  String? get supabaseEmail => _currentUser?['email'] ?? _supabase.auth.currentUser?.email;
  String? get firebasePhone => _currentUser?['phone'] ?? _firebase.currentUser?.phoneNumber;
  String get displayName => _currentUser?['full_name'] ?? 'User';
  String? get userEmail => _currentUser?['email'];
  String? get userPhone => _currentUser?['phone'];
  bool get isVerified => _currentUser?['is_verified'] == true;
  bool get isActive => _currentUser?['is_active'] == true;
  String get userRole => _currentUser?['role'] ?? 'rider';
  
  // FIXED: Signed in stream
  Stream<bool> get signedInStream => _signedInController.stream;
  
  /// Initialize auth service and check existing sessions
  Future<void> initialize() async {
    try {
      await _restoreTokenFromStorage();
      
      // Check for existing Supabase session
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null) {
        await _syncSupabaseUser(supabaseUser);
      }

      // Check for existing Firebase session
      final firebaseUser = _firebase.currentUser;
      if (firebaseUser != null && _currentUser == null) {
        await _syncFirebaseUser(firebaseUser);
      }

      // Set up listeners
      _setupAuthListeners();
      
      print('AuthService initialized. User logged in: $isLoggedIn, Has token: ${_jwtToken != null}');
    } catch (e) {
      print('AuthService initialization error: $e');
    }
  }

  /// FIXED: Single implementation of initListenersOnce
  void initListenersOnce() {
    if (!_listenersInitialized) {
      _setupAuthListeners();
      _listenersInitialized = true;
    }
  }

  /// Restore JWT token from local storage
  Future<void> _restoreTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _jwtToken = prefs.getString('jwt_token');
      
      if (_jwtToken != null) {
        await _validateAndSetCurrentUser();
      }
    } catch (e) {
      print('Error restoring token from storage: $e');
      _jwtToken = null;
    }
  }

  /// Store JWT token to local storage
  Future<void> _storeTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      _jwtToken = token;
    } catch (e) {
      print('Error storing token to storage: $e');
    }
  }

  /// Clear JWT token from storage
  Future<void> _clearTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      _jwtToken = null;
    } catch (e) {
      print('Error clearing token from storage: $e');
    }
  }

  /// Validate stored token and set current user
  Future<void> _validateAndSetCurrentUser() async {
    if (_jwtToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data['user'] ?? data;
        print('User validated from stored token: ${_currentUser?['id']}');
      } else {
        print('Token validation failed, clearing stored token');
        await _clearTokenFromStorage();
      }
    } catch (e) {
      print('Token validation error: $e');
      await _clearTokenFromStorage();
    }
  }

  /// Set up auth state listeners
  void _setupAuthListeners() {
    if (_listenersInitialized) return;
    
    // Supabase auth listener
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      print('Supabase auth event: $event');
      
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        await _syncSupabaseUser(session!.user);
        _signedInController.add(true);
      } else if (event == AuthChangeEvent.signedOut) {
        await _handleSignOut();
        _signedInController.add(false);
      }
    });

    // Firebase auth listener
    _firebase.authStateChanges().listen((user) async {
      print('Firebase auth change: ${user?.uid}');
      
      if (user != null && _currentUser == null) {
        await _syncFirebaseUser(user);
        _signedInController.add(true);
      } else if (user == null && _currentUser?['firebase_uid'] != null) {
        final supabaseUser = _supabase.auth.currentUser;
        if (supabaseUser == null) {
          await _handleSignOut();
          _signedInController.add(false);
        }
      }
    });

    _listenersInitialized = true;
    print('Auth listeners initialized');
  }

  /// ADDED: Phone verification methods for backwards compatibility
  Future<String> startPhoneVerification(String phoneNumber) async {
    try {
      print('Starting phone verification for: $phoneNumber');
      
      // Firebase phone verification
      final completer = Completer<String>();
      
      await _firebase.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          // Auto-verification completed
          try {
            final userCredential = await _firebase.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _syncFirebaseUser(userCredential.user!);
            }
          } catch (e) {
            print('Auto verification error: $e');
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
          completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent, verification ID: $verificationId');
          _pendingPhoneVerification = verificationId;
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto retrieval timeout');
          _pendingPhoneVerification = verificationId;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Phone verification error: $e');
      throw Exception('Phone verification failed: $e');
    }
  }

  /// ADDED: Confirm SMS code
  Future<void> confirmSmsCode(String verificationId, String smsCode) async {
    try {
      print('Confirming SMS code');
      
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _firebase.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _syncFirebaseUser(userCredential.user!);
        print('Phone verification successful');
      } else {
        throw Exception('Phone verification failed');
      }
    } catch (e) {
      print('SMS confirmation error: $e');
      throw Exception('Invalid verification code');
    }
  }

  /// Simple signup without OTP verification
  Future<String> signUpSimple({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      print('Starting simple registration for $email');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
        }),
      );

      print('Backend registration response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'];
        _currentUser = userData;
        
        if (data['token'] != null) {
          await _storeTokenToStorage(data['token']);
          print('JWT token stored successfully');
        }
        
        print('Backend registration successful: ${userData['id']}');
        return userData['id'];
      } else if (response.statusCode == 409) {
        throw Exception('User already exists. Please sign in instead.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      
      if (e.toString().toLowerCase().contains('already') || 
          e.toString().toLowerCase().contains('exists')) {
        throw Exception('This email is already registered. Please sign in instead.');
      }
      
      throw Exception('Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Register new user with email, password, and phone
  Future<String> signUpWithEmailAndPhone({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      print('Starting registration for $email with phone $phone');
      
      return await signUpSimple(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  /// Login with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      print('Signing in with email: $email');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['error'] ?? 'Login failed');
      }

      _currentUser = data['user'];
      
      if (data['token'] != null) {
        await _storeTokenToStorage(data['token']);
        print('JWT token stored after login');
      }

      print('Email login successful for user: ${_currentUser?['id']}');
      _signedInController.add(true);
      
    } catch (e) {
      print('Email login failed: $e');
      throw Exception('Email login failed: $e');
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      if (_jwtToken != null) {
        return _jwtToken;
      }

      final session = _supabase.auth.currentSession;
      if (session?.accessToken != null) {
        return session!.accessToken;
      }

      final firebaseUser = _firebase.currentUser;
      if (firebaseUser != null) {
        return await firebaseUser.getIdToken();
      }

      return null;
    } catch (e) {
      print('Get token error: $e');
      return null;
    }
  }

  /// Sign out from all systems
  Future<void> signOut() async {
    try {
      print('Signing out user');
      
      await _supabase.auth.signOut();
      await _firebase.signOut();
      
      await _handleSignOut();
      print('Sign out completed');
    } catch (e) {
      print('Sign out error: $e');
      await _handleSignOut();
    }
  }

  /// Handle sign out cleanup
  Future<void> _handleSignOut() async {
    _currentUser = null;
    _pendingPhoneVerification = null;
    _pendingPhoneLink = null;
    await _clearTokenFromStorage();
    print('Local auth state cleared');
  }

  /// Sync Supabase user to unified system
  Future<void> _syncSupabaseUser(User user) async {
    try {
      print('Syncing Supabase user: ${user.id}');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/sync-supabase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': user.id,
          'email': user.email,
          'phone': user.phone,
          'user_metadata': user.userMetadata,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['user'];
        _currentUser = userData;
        
        final responseData = jsonDecode(response.body);
        if (responseData['token'] != null) {
          await _storeTokenToStorage(responseData['token']);
        }
        
        print('Supabase user synced successfully');
      } else {
        print('Supabase sync failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Supabase user sync error: $e');
    }
  }

  /// Sync Firebase user to unified system
  Future<void> _syncFirebaseUser(fb.User user) async {
    try {
      print('Syncing Firebase user: ${user.uid}');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/sync-firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'email': user.email,
          'phone': user.phoneNumber,
          'displayName': user.displayName,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['user'];
        _currentUser = userData;
        
        final responseData = jsonDecode(response.body);
        if (responseData['token'] != null) {
          await _storeTokenToStorage(responseData['token']);
        }
        
        print('Firebase user synced successfully');
      } else {
        print('Firebase sync failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Firebase user sync error: $e');
    }
  }

  /// Get current user details
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      String? token = await getToken();

      if (token != null) {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/profile/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body)['user'];
          _currentUser = userData;
          return userData;
        }
      }
    } catch (e) {
      print('Get current user error: $e');
    }

    return null;
  }

  // Legacy methods for backward compatibility
  bool canLoginWithPhone(String phone) => false;

  void dispose() {
    _signedInController.close();
  }
}