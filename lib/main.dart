// lib/main.dart

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
    // Initialize the ApiClient once
    _apiClient =
        ApiClient(baseUrl: const String.fromEnvironment('API_BASE'));
    // Grab any existing session and set its token
    _session = Supabase.instance.client.auth.currentSession;
    final token = _session?.accessToken;
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
    // Update token when auth state changes
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
          ? LoginPage(api: _apiClient)             // <-- pass the ApiClient here
          : HomeShell(api: _apiClient),
    );
  }
}
