// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
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

class CabshareApp extends StatelessWidget {
  const CabshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true),
      home: Builder(
        builder: (context) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) return const LoginPage();
          return const HomeShell();
        },
      ),
    );
  }
}
