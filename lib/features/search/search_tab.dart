// lib/features/search/search_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/config_service.dart';
import '../../models/ride.dart';
import 'package:intl/intl.dart';

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
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _book(Ride r) async {
    try {
      await _api.book(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booked!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, d MMM');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _from,
              decoration: const InputDecoration(labelText: 'From'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _to,
              decoration: const InputDecoration(labelText: 'To'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(_date == null ? 'Pick date' : df.format(_date!)),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return ListTile(
                    title: Text('${r.from} → ${r.to}'),
                    subtitle: Text(
                        '${DateFormat('EEE, d MMM – HH:mm').format(r.when)} · ₹${r.price} · ${r.seats} seats · ${r.driverName}'),
                    trailing: FilledButton(
                      onPressed: () => _book(r),
                      child: const Text('Book'),
                    ),
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
