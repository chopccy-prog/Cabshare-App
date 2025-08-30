import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../models/pool_type.dart';
import '../../models/ride.dart';

class SearchTab extends StatefulWidget {
  final ApiClient api;
  const SearchTab({super.key, required this.api});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> with SingleTickerProviderStateMixin {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;

  late TabController _tab;
  PoolType _currentPool = PoolType.private;

  List<Ride> _results = [];
  bool _loading = false;
  final _df = DateFormat('EEE, dd MMM yyyy');
  final _tf = DateFormat('dd MMM, HH:mm');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      setState(() => _currentPool = _poolFromTab(_tab.index));
    });
  }

  PoolType _poolFromTab(int i) {
    switch (i) {
      case 0: return PoolType.private;
      case 1: return PoolType.commercial;
      case 2: return PoolType.fullcar;
      default: return PoolType.private;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (!mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _doSearch() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.search(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        date: _date,
        pool: _currentPool,
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

  Future<void> _bookRide(Ride r, int index) async {
    setState(() => _results[index] = r.copyWith(uiBusy: true));
    try {
      await widget.api.book(r.id);
      final updated = r.copyWith(
        booked: true,
        seats: (r.seats > 0) ? (r.seats - 1) : 0,
        uiBusy: false,
      );
      setState(() => _results[index] = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed')),
      );
    } catch (e) {
      setState(() => _results[index] = r.copyWith(uiBusy: false));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search rides'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Private pool'),
            Tab(text: 'Commercial pool'),
            Tab(text: 'Full car'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    decoration: const InputDecoration(labelText: 'From'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _to,
                    decoration: const InputDecoration(labelText: 'To'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _date == null ? 'Any date' : _df.format(_date!.toLocal()),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: _date == null ? null : () => setState(() => _date = null),
                  icon: const Icon(Icons.clear),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Pick date'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _doSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No results yet'))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) => _rideTile(_results[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideTile(Ride r, int index) {
    final isBookedOrFull = r.booked == true || r.seats <= 0;
    final busy = r.uiBusy == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${r.from} → ${r.to}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.event_seat, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 2),
                Text('${r.seats}'),
                const SizedBox(width: 12),
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 2),
                Text('${r.price}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(_tf.format(r.when.toLocal())),
                const SizedBox(width: 12),
                Icon(Icons.local_taxi, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(r.pool),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (isBookedOrFull)
                  Chip(
                    label: Text(r.seats <= 0 ? 'Full' : 'Booked'),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: (isBookedOrFull || busy) ? null : () => _bookRide(r, index),
                  icon: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// UI-only busy flag helper (kept in the ride JSON map so we can copy safely)
extension RideUiBusy on Ride {
  bool? get uiBusy => (toJson()['busy'] as bool?);
  Ride copyWith({
    String? id,
    String? from,
    String? to,
    DateTime? when,
    int? seats,
    num? price,
    String? driverName,
    String? driverPhone,
    bool? booked,
    String? pool,
    bool? uiBusy, // ui-only
  }) {
    final map = toJson();
    return Ride.fromJson({
      ...map,
      if (id != null) 'id': id,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (when != null) 'when': when.toIso8601String(),
      if (seats != null) 'seats': seats,
      if (price != null) 'price': price,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (booked != null) 'booked': booked,
      if (pool != null) 'pool': pool,
      if (uiBusy != null) 'busy': uiBusy, // stored only on client
    }..removeWhere((k, v) => v == null));
  }
}
