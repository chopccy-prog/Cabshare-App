// lib/features/rides/ride_details_page.dart
import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../services/api_client.dart';

class RideDetailsPage extends StatefulWidget {
  final Ride ride;
  const RideDetailsPage({super.key, required this.ride});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  int _seats = 1;
  bool _booking = false;

  Future<void> _book() async {
    setState(() => _booking = true);
    try {
      final res = await ApiClient.I.bookRide(widget.ride.id, seats: _seats);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booked! Ref: ${res['bookingId'] ?? 'ok'}')),
        );
        Navigator.of(context).pop(); // back to results
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.fromCity} → ${r.toCity}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(r.prettyDate),
            const SizedBox(height: 6),
            Text('Driver: ${r.driverName}'),
            const SizedBox(height: 6),
            Text('Price: ₹${r.price}'),
            const SizedBox(height: 6),
            Text('Seats available: ${r.seats}'),
            const Spacer(),
            Row(
              children: [
                const Text('Seats:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _seats,
                  items: const [1, 2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                  onChanged: (v) => setState(() => _seats = v ?? 1),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _booking ? null : _book,
                  icon: const Icon(Icons.event_seat),
                  label: _booking ? const Text('Booking...') : const Text('Book ride'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
