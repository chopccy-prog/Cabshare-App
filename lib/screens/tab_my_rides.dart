// lib/screens/tab_my_rides.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabMyRides extends StatefulWidget {
  final ApiClient api;
  const TabMyRides({super.key, required this.api});

  @override
  State<TabMyRides> createState() => _TabMyRidesState();
}

class _TabMyRidesState extends State<TabMyRides> {
  int _which = 0; // 0=Published (driver), 1=Booked (rider)
  bool _busy = false;
  String? _err;
  List<dynamic> _driver = [];
  List<dynamic> _rider = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _busy = true; _err = null; });
    try {
      final d = await widget.api.myRides(role: 'driver');
      final r = await widget.api.myRides(role: 'rider');
      setState(() { _driver = d; _rider = r; });
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _which == 0 ? _driver : _rider;

    return Column(
      children: [
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Published')),
            ButtonSegment(value: 1, label: Text('Booked')),
          ],
          selected: {_which},
          onSelectionChanged: (s) => setState(() => _which = s.first),
        ),
        const SizedBox(height: 8),
        if (_err != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_err!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? Center(child: Text(_which == 0 ? 'No rides you published yet.' : 'No rides you booked yet.'))
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = items[i] as Map<String, dynamic>;
                final from = (m['from'] ?? m['from_city'] ?? '').toString();
                final to   = (m['to']   ?? m['to_city']   ?? '').toString();
                final when = (m['when'] ?? m['start_time'] ?? '').toString();
                final seats = (m['seats'] ?? m['available_seats'] ?? '').toString();
                final pool  = (m['pool'] ?? '').toString();
                final commercial = (m['is_commercial'] == true || m['is_commercial'] == 1 || m['is_commercial'] == 'true');
                final price = (m['price_inr'] ?? m['price'] ?? '').toString();

                return ListTile(
                  leading: Icon(_which == 0 ? Icons.drive_eta : Icons.event_seat),
                  title: Text('$from → $to'),
                  subtitle: Text('When: $when • Seats: $seats • ₹$price • ${commercial ? "Commercial" : "Personal"} • ${pool.isEmpty ? "private?" : pool}'),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        ),
      ],
    );
  }
}
