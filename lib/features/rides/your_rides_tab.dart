// lib/features/rides/your_rides_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/config_service.dart';
import '../../models/ride.dart';
import 'package:intl/intl.dart';

class YourRidesTab extends StatefulWidget {
  const YourRidesTab({super.key});
  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  final _api = ApiClient(ConfigService.instance);
  final _driverName = TextEditingController();
  List<Ride> _rides = [];
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.myRides(
        driverName: _driverName.text.trim().isEmpty ? null : _driverName.text.trim(),
      );
      setState(() => _rides = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, d MMM – HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _driverName, decoration: const InputDecoration(labelText: 'Driver name (optional)')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loading ? null : _load, child: const Text('Load my rides')),
            const SizedBox(height: 16),
            Expanded(
              child: _rides.isEmpty
                  ? const Center(child: Text('No rides'))
                  : ListView.separated(
                itemCount: _rides.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final r = _rides[i];
                  return ListTile(
                    title: Text('${r.from} → ${r.to}'),
                    subtitle: Text('${df.format(r.when)} · ₹${r.price} · ${r.seats} seats · ${r.driverName}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
