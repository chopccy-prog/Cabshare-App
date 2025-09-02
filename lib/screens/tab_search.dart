// lib/screens/tab_search.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

enum RideCategory { privatePool, commercialPool, commercialFullCar }

class TabSearch extends StatefulWidget {
  final ApiClient api;
  const TabSearch({super.key, required this.api});

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _when = TextEditingController();
  RideCategory _cat = RideCategory.privatePool;

  bool _busy = false;
  String? _err;
  List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _when.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      _when.text =
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  bool _matchCategory(Map<String, dynamic> m) {
    final t = (m['ride_type'] ?? 'private').toString();
    switch (_cat) {
      case RideCategory.privatePool:
        return t == 'private';
      case RideCategory.commercialPool:
        return t == 'shared';
      case RideCategory.commercialFullCar:
        return t == 'commercial_full';
    }
  }

  Future<void> _search() async {
    setState(() { _busy = true; _err = null; });
    try {
      final list = await widget.api.searchRides(
        from: _from.text.trim(),
        to: _to.text.trim(),
        when: _when.text.trim(),
      );
      final items = list.whereType<Map<String, dynamic>>().where(_matchCategory).toList();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _openRide(Map<String, dynamic> m) async {
    final rideId = m['id'].toString();
    Map<String, dynamic>? ride;
    String? error;
    int seats = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Future<void> _load() async {
            try {
              final r = await widget.api.getRide(rideId);
              setSheet(() => ride = r);
            } catch (e) {
              setSheet(() => error = '$e');
            }
          }

          if (ride == null && error == null) {
            // ignore: discarded_futures
            _load();
          }

          final inset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: (ride == null && error == null)
                  ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
                  : (error != null)
                  ? SizedBox(height: 180, child: Text(error!))
                  : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ride!['from_location']} → ${ride!['to_location']}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('When: ${ride!['depart_date']} ${ride!['depart_time'] ?? ''}'),
                  Text('Seats left: ${ride!['seats_available']} / ${ride!['seats_total']}'),
                  Text('Price/seat: ₹${ride!['price_per_seat_inr'] ?? 0}'),
                  const Divider(height: 24),
                  Text('Driver', style: Theme.of(context).textTheme.titleMedium),
                  Text(ride!['driver']?['full_name'] ?? '—'),
                  Text(ride!['driver']?['phone'] ?? '—'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Seats:'),
                      IconButton(
                        onPressed: seats > 1 ? () => setSheet(() => seats--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$seats'),
                      IconButton(
                        onPressed: () {
                          final max = (ride!['seats_available'] ?? 1) as int;
                          if (seats < max) setSheet(() => seats++);
                        },
                        icon: const Icon(Icons.add),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await widget.api.requestBooking(rideId, seats);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking sent')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Request booking'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (e.g., Nashik)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To (e.g., Pune)'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _when,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Date (tap to pick)', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _busy ? null : _search, icon: const Icon(Icons.search), label: const Text('Search')),
              ]),
              if (_err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<RideCategory>(
            segments: const [
              ButtonSegment(value: RideCategory.privatePool,       icon: Icon(Icons.directions_car), label: Text('Private Pool')),
              ButtonSegment(value: RideCategory.commercialPool,    icon: Icon(Icons.local_taxi),    label: Text('Commercial Pool')),
              ButtonSegment(value: RideCategory.commercialFullCar, icon: Icon(Icons.local_taxi),    label: Text('Commercial Full Car')),
            ],
            selected: {_cat},
            onSelectionChanged: (s) => setState(() => _cat = s.first),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : (_items.isEmpty
              ? const Center(child: Text('No rides found for this category.'))
              : ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = _items[i];
              final from  = (m['from_location'] ?? '').toString();
              final to    = (m['to_location'] ?? '').toString();
              final when  = '${m['depart_date'] ?? ''} ${m['depart_time'] ?? ''}'.trim();
              final price = (m['price_per_seat_inr'] ?? '').toString();
              final seats = (m['seats_available'] ?? '').toString();
              return ListTile(
                title: Text('$from → $to'),
                subtitle: Text('When: $when • Seats: $seats • ₹$price'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openRide(m),
              );
            },
          )),
        ),
      ],
    );
  }
}
