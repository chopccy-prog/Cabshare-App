import 'package:flutter/material.dart';
import '../../core/api.dart';

class RideDetailsPage extends StatelessWidget {
  final Ride ride;
  const RideDetailsPage({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ride.from} → ${ride.to}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${ride.dateLabel} • ${ride.timeLabel}'),
            const SizedBox(height: 8),
            Text('Price: ₹${ride.price}'),
            const SizedBox(height: 8),
            Text('Seats left: ${ride.spots}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ride.spots > 0
                    ? () async {
                  try {
                    await Api.bookRide(ride.id); // implement in Api
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booked!')),
                      );
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                }
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Book seat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
