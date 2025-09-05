// lib/screens/ride_detail.dart
//
// Displays detailed information about a specific ride and allows the
// user to request a booking.  If the ride supports auto-approval,
// the booking will immediately be confirmed.  Otherwise it will be
// pending until the driver approves it.  After submitting a booking,
// the screen shows a snack bar with the result.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideDetail extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> ride;
  const RideDetail({super.key, required this.api, required this.ride});

  @override
  State<RideDetail> createState() => _RideDetailState();
}

class _RideDetailState extends State<RideDetail> {
  int _seatsToBook = 1;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final from = ride['from_location'] ?? ride['from'];
    final to = ride['to_location'] ?? ride['to'];
    final date = ride['depart_date'] ?? '';
    final time = ride['depart_time'] ?? '';
    final price = ride['price_per_seat_inr'] ?? '';
    final seatsAvail = ride['seats_available'] ?? ride['seats_total'] ?? 0;
    final rideType = ride['ride_type'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$from → $to', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Date: $date'),
            Text('Time: $time'),
            Text('Price per seat: ₹$price'),
            Text('Seats available: $seatsAvail'),
            Text('Type: $rideType'),
            const SizedBox(height: 24),
            Text('Select seats to book:'),
            DropdownButton<int>(
              value: _seatsToBook,
              onChanged: (val) => setState(() => _seatsToBook = val ?? 1),
              items: List.generate(seatsAvail, (i) => i + 1)
                  .map((n) => DropdownMenuItem(
                value: n,
                child: Text(n.toString()),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_success != null)
              Text(
                _success!,
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : () async {
                setState(() {
                  _busy = true;
                  _error = null;
                  _success = null;
                });
                try {
                  // Pass uid query parameter as fallback when bearer token is absent
                  final user = Supabase.instance.client.auth.currentUser;
                  final booking = await widget.api.requestBooking(
                    ride['id'] as String,
                    _seatsToBook,
                    uid: user?.id,
                  );
                  setState(() => _success =
                  'Booking ${booking['status']} (${booking['seats']} seat${booking['seats'] == 1 ? '' : 's'})');
                } catch (e) {
                  setState(() => _error = e.toString());
                } finally {
                  setState(() => _busy = false);
                }
              },
              child: const Text('Book Seat'),
            ),
          ],
        ),
      ),
    );
  }
}