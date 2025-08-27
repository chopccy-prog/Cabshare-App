// lib/features/rides/your_rides_tab.dart
import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../services/api_client.dart';
import 'ride_details_page.dart';

class YourRidesTab extends StatefulWidget {
  const YourRidesTab({super.key});
  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  bool _loading = true;
  String? _error;
  List<Ride> _rides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // “All rides” listing by calling search without filters isn’t supported,
      // so we fetch “today’s” between any cities as a simple demo.
      // Replace with a GET /rides/mine when backend is ready.
      final today = DateTime.now();
      _rides = await ApiClient.I.searchRides(from: '', to: '', date: today);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your rides')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.builder(
        itemCount: _rides.length,
        itemBuilder: (_, i) {
          final r = _rides[i];
          return Card(
            child: ListTile(
              title: Text('${r.fromCity} → ${r.toCity} • ₹${r.price}'),
              subtitle: Text(r.prettyDate),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RideDetailsPage(ride: r)),
              ),
            ),
          );
        },
      ),
    );
  }
}
