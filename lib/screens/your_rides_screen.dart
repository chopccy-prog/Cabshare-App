import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/ride.dart';

class YourRidesScreen extends StatefulWidget {
  @override
  _YourRidesScreenState createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen> {
  final SupabaseService supabaseService = SupabaseService();
  List<Ride> published = [], booked = [];
  bool isPublished = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    try {
      final pub = await supabaseService.getPublishedRides();
      final book = await supabaseService.getBookedRides();
      setState(() {
        published = pub;
        booked = book;
        isLoading = false;
      });
    } catch (e) {
      print('Rides load error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rides = isPublished ? published : booked;
    return Scaffold(
      appBar: AppBar(title: Text('Your Rides')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          ToggleButtons(
            children: [Text('Published'), Text('Booked')],
            isSelected: [isPublished, !isPublished],
            onPressed: (index) => setState(() => isPublished = index == 0),
          ),
          Expanded(
            child: rides.isEmpty
                ? Center(child: Text(isPublished ? 'No rides published.' : 'No rides booked. Please log in.'))
                : ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return ListTile(
                  title: Text('${ride.fromCity ?? 'Unknown'} to ${ride.toCity ?? 'Unknown'}'),
                  subtitle: Text('Date: ${ride.departDate ?? DateTime.now()} | Status: ${ride.status}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Cancellation logic to add later
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