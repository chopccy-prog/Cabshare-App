// lib/features/search/search_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../rides/services/ride_service.dart';
import '../rides/ui/ride_results_page.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  final _svc = RideService();

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.search(
        from: _from.text,
        to: _to.text,
        date: _date,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RideResultsPage(rides: items),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _from,
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _to,
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(df.format(_date)),
              trailing: IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: Text(_loading ? 'Searching…' : 'Search rides'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tip: Phone & PC must be on same Wi-Fi. Backend at http://YOUR_PC_IP:5000',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
