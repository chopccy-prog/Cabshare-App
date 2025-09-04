import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/ride.dart';

class YourRidesScreen extends StatefulWidget {
  @override
  _YourRidesScreenState createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen> {
  final supabaseService = SupabaseService();
  List<Ride> published = [], booked = [];
  bool isPublished = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      published = supabaseService.getPublishedRides() as List<Ride>;
      booked = supabaseService.getBookedRides() as List<Ride>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rides = isPublished ? published : booked;
    return Scaffold(
      appBar: AppBar(title: Text('Your Rides')),
      body: Column(
        children: [
          ToggleButtons(
            children: [Text('Published'), Text('Booked')],
            isSelected: [isPublished, !isPublished],
            onPressed: (index) => setState(() => isPublished = index == 0),
          ),
          Expanded(
            child: rides.isEmpty
                ? Center(child: Text(isPublished ? 'No rides published.' : 'No rides booked.'))
                : ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return ListTile(
                  title: Text('${ride.fromCity} to ${ride.toCity}'),
                  subtitle: Text('Date: ${ride.departDate} | Status: ${ride.status}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Add cancellation logic later
                    },
                    child: Text('Cancel'),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(onPressed: _refresh, child: Text('Refresh')),
        ],
      ),
    );
  }
}