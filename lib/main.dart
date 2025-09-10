import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'services/api_client.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase (for phone auth)
  await Firebase.initializeApp();

  // 2) Supabase (for backend auth/session if you need it)
  await supa.Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    debug: true,
  );

  runApp(const CabshareApp());
}

class CabshareApp extends StatefulWidget {
  const CabshareApp({super.key});
  @override
  State<CabshareApp> createState() => _CabshareAppState();
}

class _CabshareAppState extends State<CabshareApp> {
  late final ApiClient _apiClient;

  fb.User? _fbUser;                 // Firebase
  supa.Session? _sbSession;         // Supabase

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(
      baseUrl: const String.fromEnvironment('API_BASE'),
    );

    // Seed initial state
    _fbUser = fb.FirebaseAuth.instance.currentUser;
    _sbSession = supa.Supabase.instance.client.auth.currentSession;

    // Prefer Firebase ID token for backend bearer if present
    _updateBearerFromFirebase(_fbUser);
    // Fallback to Supabase access token if present
    _updateBearerFromSupabase(_sbSession);

    // Listen for Firebase token / user changes
    fb.FirebaseAuth.instance.idTokenChanges().listen((user) async {
      _fbUser = user;
      await _updateBearerFromFirebase(user);
      setState(() {});
    });

    // Listen for Supabase auth changes (optional)
    supa.Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      _sbSession = event.session;
      _updateBearerFromSupabase(event.session);
      setState(() {});
    });
  }

  Future<void> _updateBearerFromFirebase(fb.User? user) async {
    final idToken = await user?.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      _apiClient.setAuthToken(idToken);
    }
  }

  void _updateBearerFromSupabase(supa.Session? session) {
    final token = session?.accessToken;
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _fbUser != null || _sbSession != null;
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true),
      home: signedIn
          ? HomeShell(api: _apiClient)
          : LoginPage(api: _apiClient),
    );
  }
}
