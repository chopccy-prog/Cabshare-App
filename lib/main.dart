// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/api_client.dart';
import 'screens/login_page.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase (for phone auth user identity)
  await Firebase.initializeApp();

  // 2) Supabase (for your DB / session token to call backend if needed)
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
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(
      // if you prefer dart-define, leave as is:
      base: const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true),
      // Keep your original logic: show Login first, then HomeShell after login.
      // If your LoginPage sets up Firebase user/Supabase session, HomeShell will work.
      home: LoginPage(api: _api),
      // If you already manage session elsewhere, you can swap to:
      // home: HomeShell(api: _api),
    );
  }
}
