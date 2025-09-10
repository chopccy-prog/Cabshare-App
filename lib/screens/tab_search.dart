import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'ride_detail.dart';

class TabSearch extends StatefulWidget {
  final ApiClient api;
  const TabSearch({super.key, required this.api});

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final _fromCtl = TextEditingController(text: 'Nashik');
  final _toCtl = TextEditingController(text: 'Pune');
  DateTime _date = DateTime.now();
  String? _type; // private | private_pool | commercial_pool
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final when = _date.toIso8601String().substring(0, 10);
      final list = await widget.api.searchRides(
        from: _fromCtl.text.trim(),
        to: _toCtl.text.trim(),
        when: when,
        type: _type,
      );
      setState(() => _results = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Search Rides', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          TextField(controller: _fromCtl, decoration: const InputDecoration(labelText: 'From city')),
          const SizedBox(height: 8),
          TextField(controller: _toCtl, decoration: const InputDecoration(labelText: 'To city')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 0)),
                      lastDate: DateTime.now().add(const Duration(days: 120)),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Text('Date: ${_date.toLocal().toString().substring(0, 10)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any type')),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'private_pool', child: Text('Private pool')),
                    DropdownMenuItem(value: 'commercial_pool', child: Text('Commercial pool')),
                  ],
                  onChanged: (v) => setState(() => _type = v),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _search,
            child: _loading ? const CircularProgressIndicator.adaptive() : const Text('Search'),
          ),
          const SizedBox(height: 16),
          for (final r in _results) _RideTile(ride: r, api: widget.api),
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  final Map<String, dynamic> ride;
  final ApiClient api;
  const _RideTile({required this.ride, required this.api});

  @override
  Widget build(BuildContext context) {
    final from = ride['from_city'] ?? ride['from'] ?? 'unknown';
    final to = ride['to_city'] ?? ride['to'] ?? 'unknown';
    final start = (ride['start_time'] ?? '').toString().replaceFirst('T', ' ');
    final price = ride['price_inr']; // normalized
    final type = (ride['type'] ?? '').toString();

    return Card(
      child: ListTile(
        title: Text('$from → $to'),
        subtitle: Text('$start • ₹${price ?? 0} • $type'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RideDetail(api: api, ride: ride),
            ),
          );
        },
      ),
    );
  }
}
