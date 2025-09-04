import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseService supabaseService = SupabaseService();

  Future<void> _bookRide() async {
    // Placeholder: Replace with actual ride ID, seats, etc.
    await supabaseService.bookRide('ride-id-here', 1, 'from-stop', 'to-stop');
    Navigator.pushNamed(context, '/inbox');  // Auto-open inbox after booking
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Search Rides Page'),
            ElevatedButton(
              onPressed: _bookRide,
              child: Text('Book Ride (Test)'),
            ),
          ],
        ),
      ),
    );
  }
}