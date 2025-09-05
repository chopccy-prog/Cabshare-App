// lib/main.dart
//
// Revised entry point for the Work Setu‑Cab Share Flutter app.
//
// This version initializes Supabase, creates a single [ApiClient]
// instance with the API base URL from `--dart-define=API_BASE`, and
// listens for authentication state changes to update the bearer token.
// It passes the client into [HomeShell] so that all screens share the
// same API instance and credentials.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_client.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
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
  Session? _session;

  @override
  void initState() {
    super.initState();
    // Instantiate the API client with the base URL from dart-define.
    _apiClient =
        ApiClient(baseUrl: const String.fromEnvironment('API_BASE'));
    // Set initial session/token if already signed in.
    _session = Supabase.instance.client.auth.currentSession;
    final token = _session?.accessToken;
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
    // Listen for auth state changes and update API token accordingly.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _session = session;
      });
      _apiClient.setAuthToken(session?.accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true),
      home: _session == null
          ? const LoginPage()
          : HomeShell(api: _apiClient),
    );
  }
}