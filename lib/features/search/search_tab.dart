import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/models/ride.dart';
import '../../core/config_service.dart';


class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _api = ApiClient(ConfigService.instance);
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  List<Ride> _results = [];
  bool _loading = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date ?? DateTime.now(),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final list = await _api.search(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        date: _date,
      );
      setState(() => _results = list);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _book(Ride r) async {
    try {
      await _api.book(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booked ride ${r.from} → ${r.to} on ${r.when}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search rides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _from, decoration: const InputDecoration(labelText: 'From city')),
          const SizedBox(height: 12),
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'To city')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_date == null ? 'When: (optional)' : 'When: $_date'),
              ),
              OutlinedButton(onPressed: _pickDate, child: const Text('Pick')),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _loading ? null : _search, child: const Text('Search')),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          for (final r in _results)
            Card(
              child: ListTile(
                title: Text('${r.from} → ${r.to}'),
                subtitle: Text('${r.driverName} • ₹${r.price} • ${r.seats} seats • ${r.when}'),
                trailing: IconButton(icon: const Icon(Icons.check_circle), onPressed: () => _book(r)),
              ),
            ),
          if (!_loading && _results.isEmpty) const Center(child: Padding(
              padding: EdgeInsets.all(12.0), child: Text('No rides yet. Try different filters.'))),
        ],
      ),
    );
  }
}
