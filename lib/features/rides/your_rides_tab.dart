// lib/features/rides/your_rides_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/ride.dart';

class YourRidesTab extends StatefulWidget {
  final ApiClient api;
  const YourRidesTab({super.key, required this.api});

  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  bool _busy = false;
  List<Ride> _rides = [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final list = await widget.api.myRides(driverName: '');
      if (!mounted) return;
      setState(() => _rides = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Rides'),
        actions: [
          IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
          ? const Center(child: Text('No rides yet'))
          : ListView.separated(
        itemCount: _rides.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = _rides[i];
          final d = r.when;
          final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
          final tag = r.booked ? 'BOOKED' : 'PUBLISHED';
          final tagColor = r.booked ? Colors.green : Colors.blueGrey;

          return ListTile(
            title: Text('${r.from} → ${r.to}'),
            subtitle: Text('$date  $time  • ₹${r.price}  • seats: ${r.seats}  • ${r.pool}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.15),
                border: Border.all(color: tagColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tag, style: TextStyle(color: tagColor, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}
