import 'package:flutter/material.dart';
import '../services/api_client.dart';

class RideDetailsPage extends StatefulWidget {
  final String rideId;
  final ApiClient api;
  const RideDetailsPage({super.key, required this.rideId, required this.api});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  Map<String, dynamic>? ride;
  int seats = 1;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final r = await widget.api.getRide(widget.rideId);
      setState(() { ride = r; });
    } catch (e) {
      setState(() { error = '$e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _book() async {
    try {
      await widget.api.requestBooking(widget.rideId, seats);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking sent. Check Inbox / Your Rides.'))
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: const Text('Ride')), body: Center(child: Text(error!)));
    final r = ride!;
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r['from']} → ${r['to']}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('When: ${r['depart_date']} ${r['depart_time'] ?? ''}'),
            Text('Seats left: ${r['seats_available']} / ${r['seats_total']}'),
            Text('Price/seat: ₹${r['price_per_seat_inr'] ?? r['price_inr'] ?? 0}'),
            const Divider(height: 32),
            Text('Driver', style: Theme.of(context).textTheme.titleMedium),
            Text(r['driver']?['full_name'] ?? '—'),
            Text(r['driver']?['phone'] ?? '—'),
            const Divider(height: 32),
            Row(
              children: [
                const Text('Seats:'),
                const SizedBox(width: 12),
                IconButton(onPressed: seats>1?(){ setState(()=> seats--); }:null, icon: const Icon(Icons.remove)),
                Text('$seats'),
                IconButton(onPressed: (){
                  final max = (r['seats_available'] ?? 1) as int;
                  if (seats < max) setState(()=> seats++);
                }, icon: const Icon(Icons.add)),
                const Spacer(),
                ElevatedButton(onPressed: _book, child: const Text('Request booking'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
