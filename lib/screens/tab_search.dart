// lib/screens/tab_search.dart
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
  // shared cities (same list used in Publish screen)
  static const _cities = <String>[
    'Bengaluru', 'Hyderabad', 'Chennai', 'Pune', 'Mumbai', 'Delhi', 'Gurugram',
    'Noida', 'Kolkata', 'Ahmedabad'
  ];

  String? _fromCity;
  String? _toCity;
  DateTime? _date; // pick just the date (backend expects yyyy-MM-dd)
  String? _type;   // private_pool | commercial_pool | commercial_full_car

  bool _loading = false;
  List<Map<String, dynamic>> _results = const [];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _runSearch() async {
    if (_fromCity == null || _toCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose both From and To cities.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final when = _date == null
          ? null
          : "${_date!.year.toString().padLeft(4, '0')}-"
          "${_date!.month.toString().padLeft(2, '0')}-"
          "${_date!.day.toString().padLeft(2, '0')}";
      final list = await widget.api.searchRides(
        from: _fromCity,
        to: _toCity,
        when: when,
        type: _type,
      );
      setState(() => _results = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _cityPicker({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _typeChips() {
    const types = [
      ['private_pool', 'Private pool'],
      ['commercial_pool', 'Commercial pool'],
      ['commercial_full_car', 'Commercial Full car'],
    ];
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final selected = _type == t[0];
        return ChoiceChip(
          label: Text(t[1]),
          selected: selected,
          onSelected: (_) => setState(() => _type = t[0]),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;

    return Scaffold(
      appBar: AppBar(title: const Text('Search rides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cityPicker(
            label: 'From city',
            value: _fromCity,
            onChanged: (v) => setState(() => _fromCity = v),
          ),
          const SizedBox(height: 12),
          _cityPicker(
            label: 'To city',
            value: _toCity,
            onChanged: (v) => setState(() => _toCity = v),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Date (optional)',
              hintText: 'Tap to pick',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDate,
              ),
            ),
            controller: TextEditingController(
              text: _date == null
                  ? ''
                  : "${_date!.year.toString().padLeft(4, '0')}-"
                  "${_date!.month.toString().padLeft(2, '0')}-"
                  "${_date!.day.toString().padLeft(2, '0')}",
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _typeChips(),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _runSearch,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Search'),
          ),
          const SizedBox(height: 20),
          if (_results.isEmpty) const Text('No results yet. Try searching.'),
          ..._results.map((ride) => _RideTile(api: api, ride: ride)).toList(),
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  final ApiClient api;
  final Map<String, dynamic> ride;
  const _RideTile({required this.api, required this.ride});

  @override
  Widget build(BuildContext context) {
    final from = ride['from_location'] ?? ride['from_city'] ?? '-';
    final to = ride['to_location'] ?? ride['to_city'] ?? '-';
    final dt = ride['depart_at'] ?? ride['departure_at'] ?? '';
    final price = ride['price_per_seat_inr'] ?? ride['fare_per_seat_inr'] ?? '-';

    return Card(
      child: ListTile(
        title: Text('$from → $to'),
        subtitle: Text('Depart: $dt     ₹$price/seat'),
        trailing: const Icon(Icons.chevron_right),
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
