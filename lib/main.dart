import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/api_client.dart';
import 'services/auth_service.dart';

import 'screens/login_page.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase (values come from --dart-define)
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    debug: true,
  );

  // Firebase (for phone OTP)
  await Firebase.initializeApp();

  // Start unified listeners (your existing service)
  AuthService().initListenersOnce();

  runApp(const CabshareApp());
}

class CabshareApp extends StatefulWidget {
  const CabshareApp({super.key});

  @override
  State<CabshareApp> createState() => _CabshareAppState();
}

class _CabshareAppState extends State<CabshareApp> {
  late final ApiClient _api;
  fb.User? _fbUser; // Firebase user (if linked)

  bool get _isSignedIn {
    final sbSession = Supabase.instance.client.auth.currentSession;
    return _fbUser != null || sbSession != null;
  }

  @override
  void initState() {
    super.initState();

    // Single shared ApiClient for the whole app
    _api = ApiClient(baseUrl: const String.fromEnvironment('API_BASE'));

    // Seed tokens from current states
    _fbUser = fb.FirebaseAuth.instance.currentUser;
    _seedApiFromSupabase(Supabase.instance.client.auth.currentSession);
    _seedApiFromFirebase(_fbUser);

    // Listen to Firebase token/user changes
    fb.FirebaseAuth.instance.idTokenChanges().listen((user) async {
      _fbUser = user;
      await _seedApiFromFirebase(user);
      if (mounted) setState(() {});
    });

    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      _seedApiFromSupabase(session);
      if (mounted) setState(() {});
    });
  }

  // Prefer Supabase access token for our backend Bearer
  void _seedApiFromSupabase(Session? session) {
    final token = session?.accessToken;
    _api.setAuthToken((token != null && token.isNotEmpty) ? token : null);
  }

  // If you also want to support Firebase-only flows later,
  // you can forward Firebase ID token to backend (if your backend accepts it).
  Future<void> _seedApiFromFirebase(fb.User? user) async {
    // Currently we keep Supabase token as primary.
    // If you want to use Firebase token instead, uncomment below:
    // final idTok = await user?.getIdToken();
    // if (idTok != null && idTok.isNotEmpty) _api.setAuthToken(idTok);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true),
      home: _isSignedIn ? HomeShell(api: _api) : LoginPage(api: _api),
    );
  }
}
