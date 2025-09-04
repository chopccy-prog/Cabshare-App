import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService supabaseService = SupabaseService();
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabaseService.supabase.auth.currentUser;
    setState(() => email = user?.email);
  }

  Future<void> _signOut() async {
    await supabaseService.signOut();
    setState(() => email = null);
    // Navigate to login or home (add navigation logic)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Signed in as: ${email ?? 'Not logged in'}'),
            ElevatedButton(
              onPressed: email == null ? null : _signOut,
              child: Text(email == null ? 'Log In' : 'Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}