import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/ride.dart';

class YourRidesTab extends StatefulWidget {
  final ApiClient api;
  final String currentUser;
  const YourRidesTab({super.key, required this.api, required this.currentUser});

  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  final _driverName = TextEditingController();
  List<Ride> _rides = [];
  bool _loading = false;

  @override
  void dispose() {
    _driverName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.myRides(driverName: _driverName.text.trim().isEmpty ? null : _driverName.text.trim());
      setState(() => _rides = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Rides')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _driverName, decoration: const InputDecoration(labelText: 'Filter by driver name')),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(onPressed: _load, child: const Text('Refresh')),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _rides.isEmpty
                  ? const Center(child: Text('No rides yet'))
                  : ListView.builder(
                itemCount: _rides.length,
                itemBuilder: (_, i) {
                  final r = _rides[i];
                  return ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text('${r.from} → ${r.to}'),
                    subtitle: Text('${r.driverName ?? '-'} • ${r.when?.toLocal()}'),
                    trailing: Text(r.price != null ? '₹${r.price!.toStringAsFixed(0)}' : ''),
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
