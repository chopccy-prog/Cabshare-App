import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_client.dart';
import '../../data/models/ride.dart';
import '../trip/ride_details_page.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  String? _error;
  List<Ride> _results = [];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _search() async {
    setState(() { _loading = true; _error = null; _results = []; });
    try {
      final q = <String, dynamic>{
        if (_from.text.trim().isNotEmpty) 'from': _from.text.trim(),
        if (_to.text.trim().isNotEmpty) 'to': _to.text.trim(),
        if (_date != null) 'date': DateFormat('yyyy-MM-dd').format(_date!),
      };
      final list = await ApiClient.I.getList('/rides', query: q);
      setState(() => _results = list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            Row(children: [
              Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (area)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _to,   decoration: const InputDecoration(labelText: 'To (area)'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_date == null ? 'Pick date' : df.format(_date!)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _loading ? null : _search, icon: const Icon(Icons.search), label: const Text('Search')),
            ]),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty && !_loading
                  ? const Center(child: Text('No rides yet. Try different filters.'))
                  : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (ctx, i) {
                  final r = _results[i];
                  return ListTile(
                    title: Text('${r.origin} → ${r.destination}'),
                    subtitle: Text('${df.format(r.departure)} • ₹${r.price} • ${r.seats} seats'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RideDetailsPage(ride: r)),
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
