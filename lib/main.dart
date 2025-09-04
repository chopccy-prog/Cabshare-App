import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lrzcnoaqooldywflixkb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxyemNub2Fxb29sZHl3ZmxpeGtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxMTAzMTAsImV4cCI6MjA3MDY4NjMxMH0.82PG2QFVL4lMrqE8E9Es3bJSQZOTpFRo9JXO8TQmxPE',
  );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print(details.toString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform error: $error\n$stack');
    return true;
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Supabase.instance.client.auth.currentUser == null ? '/login' : '/profile',
      routes: {
        '/login': (context) => LoginScreen(),
        '/profile': (context) => ProfileScreen(),
        // Add other routes (e.g., '/home' for bottom nav)
      },
    );
  }
}