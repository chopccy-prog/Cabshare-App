// lib/main.dart - Enhanced with proper initialization and new theme
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'core/theme/app_theme.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';
import 'screens/splash_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check environment configuration
  if (!Env.isConfigured) {
    debugPrint('ERROR: Environment not properly configured!');
    debugPrint('Configuration: ${Env.debugInfo}');
    runApp(const ErrorApp(message: 'Environment configuration missing'));
    return;
  }

  try {
    // Initialize Supabase (values come from --dart-define)
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: Env.isDevelopment,
    );
    debugPrint('✅ Supabase initialized');

    // Initialize Firebase (for phone OTP)
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // Initialize AuthService
    await AuthService().initialize();
    debugPrint('✅ AuthService initialized');

    runApp(const CabshareApp());
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
    runApp(ErrorApp(message: 'Initialization failed: $e'));
  }
}

class CabshareApp extends StatefulWidget {
  const CabshareApp({super.key});

  @override
  State<CabshareApp> createState() => _CabshareAppState();
}

class _CabshareAppState extends State<CabshareApp> {
  late final ApiClient _api;
  late final AuthService _authService;
  fb.User? _fbUser;
  bool _isInitializing = true;

  bool get _isSignedIn {
    final sbSession = Supabase.instance.client.auth.currentSession;
    return _fbUser != null || sbSession != null || _authService.isLoggedIn;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _api = ApiClient(baseUrl: Env.apiBase);
      _authService = AuthService();

      _fbUser = fb.FirebaseAuth.instance.currentUser;
      _seedApiFromSupabase(Supabase.instance.client.auth.currentSession);
      await _seedApiFromFirebase(_fbUser);

      fb.FirebaseAuth.instance.idTokenChanges().listen((user) async {
        _fbUser = user;
        await _seedApiFromFirebase(user);
        if (mounted) setState(() {});
      });

      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        final session = event.session;
        _seedApiFromSupabase(session);
        if (mounted) setState(() {});
      });

    } catch (e) {
      debugPrint('App initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _seedApiFromSupabase(Session? session) {
    final token = session?.accessToken;
    _api.setAuthToken((token != null && token.isNotEmpty) ? token : null);
  }

  Future<void> _seedApiFromFirebase(fb.User? user) async {
    // Keep Supabase token as primary
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worksetu CabShare - Professional Ride Sharing',
      theme: AppTheme.lightTheme, // Use new unified theme
      home: _isInitializing 
        ? const SplashScreen()
        : _isSignedIn 
          ? HomeShell(api: _api)
          : LoginPage(api: _api),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CabShare Error',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space2XL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space2XL),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(height: AppTheme.space2XL),
                const Text(
                  'Configuration Error',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.space2XL),
                const Text(
                  'Please check your environment configuration and restart the app.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
