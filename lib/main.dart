import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';  // New home with bottom nav

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lrzcnoaqooldywflixkb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxyemNub2Fxb29sZHl3ZmxpeGtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxMTAzMTAsImV4cCI6MjA3MDY4NjMxMH0.82PG2QFVL4lMrqE8E9Es3bJSQZOTpFRo9JXO8TQmxPE',
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      print('Auth state changed: ${data.event}');
      if (data.event == 'SIGNED_OUT') {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Supabase.instance.client.auth.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}