import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class YourRidesScreen extends StatefulWidget {
  @override
  _YourRidesScreenState createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen> {
  final supabase = Supabase.instance.client;
  final String testUserId = '00000000-0000-0000-0000-000000000000'; // Replace with your test user's UUID from Supabase dashboard

  List<dynamic> publishedRides = [];
  List<dynamic> bookedRides = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    try {
      // For Published (rides you published as driver)
      final publishedResponse = await supabase
          .from('rides')
          .select('*')
          .eq('driver_id', testUserId); // Fixed: Use UUID instead of 'mine'

      // For Booked (assume a 'bookings' table; adjust if your schema is different)
      final bookedResponse = await supabase
          .from('bookings')
          .select('*, rides(*)') // Join with rides if needed
          .eq('rider_id', testUserId); // Fixed: Use UUID instead of 'mine'

      setState(() {
        publishedRides = publishedResponse;
        bookedRides = bookedResponse;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cabshare')),
      body: Column(
        children: [
          ToggleButtons(
            children: [Text('Published'), Text('Booked')],
            isSelected: [true, false], // Add state for toggling if needed
            onPressed: (index) {
              // Add logic to switch tabs
            },
          ),
          if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
          if (isLoading) Center(child: CircularProgressIndicator()),
          if (!isLoading && publishedRides.isEmpty) Center(child: Text('No rides you published yet.')),
          // Add ListView for rides here (e.g., ListView.builder to display rides)
          ElevatedButton(onPressed: _fetchRides, child: Text('Refresh')),
        ],
      ),
    );
  }
}