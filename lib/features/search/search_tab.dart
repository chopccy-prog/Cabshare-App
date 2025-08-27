// lib/features/search/search_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ride.dart';
import '../../services/api_client.dart';
import '../rides/ride_details_page.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;
  List<Ride> _results = [];
  String? _error;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final rides = await ApiClient.I.searchRides(
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
        date: _date,
      );
      setState(() => _results = rides);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM').format(_date);
    return Scaffold(
      appBar: AppBar(title: const Text('Search rides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _fromCtrl,
            decoration: const InputDecoration(
              labelText: 'From',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toCtrl,
            decoration: const InputDecoration(
              labelText: 'To',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Date: $dateLabel')),
              FilledButton.tonal(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _search,
            child: _loading ? const CircularProgressIndicator() : const Text('Search'),
          ),
          const SizedBox(height: 20),

          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),

          if (_results.isEmpty && !_loading && _error == null)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('No results yet. Search to see rides.'),
            )),

          for (final r in _results)
            Card(
              child: ListTile(
                title: Text('${r.fromCity} → ${r.toCity} • ₹${r.price}'),
                subtitle: Text('${r.prettyDate} • seats ${r.seats}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RideDetailsPage(ride: r),
                  ));
                },
              ),
            ),
        ],
      ),
    );
  }
}
