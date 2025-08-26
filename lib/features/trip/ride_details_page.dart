import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ride.dart';
import '../../data/api_client.dart';

class RideDetailsPage extends StatefulWidget {
  final Ride ride;
  const RideDetailsPage({super.key, required this.ride});
  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  bool _busy = false;
  String? _msg;

  Future<void> _requestToJoin() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final res = await ApiClient.I.postJson('/rides/${widget.ride.id}/request', {});
      setState(() => _msg = 'Request sent! Seats left: ${res['ride']?['seats']}');
    } catch (e) {
      setState(() => _msg = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final df = DateFormat('EEE, d MMM • HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r.origin} → ${r.destination}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(df.format(r.departure)),
          const SizedBox(height: 6),
          Text('Driver: ${r.driverName}'),
          const SizedBox(height: 6),
          Text('Seats left: ${r.seats}'),
          const SizedBox(height: 6),
          Text('Price: ₹${r.price}'),
          const Spacer(),
          if (_msg != null) Text(_msg!, style: TextStyle(color: _msg!.startsWith('Failed') ? Colors.red : Colors.green)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _requestToJoin,
            icon: const Icon(Icons.send),
            label: const Text('Request to join'),
          ),
        ]),
      ),
    );
  }
}
