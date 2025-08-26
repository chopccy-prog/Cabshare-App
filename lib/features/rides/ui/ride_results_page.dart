// lib/features/rides/ui/ride_results_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../rides/models/ride.dart';
import '../../rides/services/ride_service.dart';

class RideResultsPage extends StatelessWidget {
  final List<Ride> rides;
  const RideResultsPage({super.key, required this.rides});

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('EEE dd MMM, HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Available rides')),
      body: rides.isEmpty
          ? const Center(child: Text('No rides found'))
          : ListView.separated(
        itemCount: rides.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = rides[i];
          return ListTile(
            title: Text('${r.from} → ${r.to}'),
            subtitle: Text('${tf.format(r.dateTime)} • ${r.seatsAvailable} seats • ₹${r.price.toStringAsFixed(0)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDetail(context, r),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Ride r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _RideDetailSheet(ride: r),
    );
  }
}

class _RideDetailSheet extends StatefulWidget {
  final Ride ride;
  const _RideDetailSheet({required this.ride});

  @override
  State<_RideDetailSheet> createState() => _RideDetailSheetState();
}

class _RideDetailSheetState extends State<_RideDetailSheet> {
  final _svc = RideService();
  int _seats = 1;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final tf = DateFormat('EEE dd MMM, HH:mm');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('${r.from} → ${r.to}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${tf.format(r.dateTime)} • ₹${r.price.toStringAsFixed(0)}'),
          ),
          Row(
            children: [
              const Text('Seats:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _seats,
                items: List.generate(r.seatsAvailable.clamp(0, 6), (i) => i + 1)
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => setState(() => _seats = v ?? 1),
              ),
              const Spacer(),
              Text('${r.seatsAvailable} available'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () async {
                setState(() => _busy = true);
                try {
                  await _svc.book(rideId: r.id, seats: _seats);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booked!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking failed: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
              icon: const Icon(Icons.event_seat),
              label: Text(_busy ? 'Booking…' : 'Book seats'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancellation cashback: ${r.cashbackOnCancelPercent}%',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
