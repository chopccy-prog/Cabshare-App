import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/models/ride.dart';
import '../../core/config_service.dart';


class YourRidesTab extends StatefulWidget {
  const YourRidesTab({super.key});
  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  final _api = ApiClient(ConfigService.instance);
  final _driverName = TextEditingController(); // simple filter
  List<Ride> _rides = [];
  bool _loading = false;

  Future<void> _load() async {
    if (_driverName.text.trim().isEmpty) {
      setState(() => _rides = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _api.myRides(driverName: _driverName.text.trim());
      setState(() => _rides = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your rides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _driverName, decoration: const InputDecoration(labelText: 'Filter by driver name')),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Load')),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator()),
          for (final r in _rides)
            ListTile(
              title: Text('${r.from} → ${r.to}'),
              subtitle: Text('${r.when} • ₹${r.price} • seats ${r.seats}'),
            ),
          if (!_loading && _rides.isEmpty) const Center(child: Padding(
              padding: EdgeInsets.all(12.0), child: Text('No rides. Publish one!'))),
        ],
      ),
    );
  }
}
