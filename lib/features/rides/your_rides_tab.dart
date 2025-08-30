import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../models/ride.dart';

class YourRidesTab extends StatefulWidget {
  final ApiClient api;
  const YourRidesTab({super.key, required this.api});

  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  bool _loading = false;
  List<Ride> _rides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.myRides();
      list.sort((a, b) => b.when.compareTo(a.when)); // latest first
      setState(() => _rides = list);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your rides'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: _loading
          ? const LinearProgressIndicator()
          : _rides.isEmpty
          ? const Center(child: Text('No rides yet'))
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (ctx, i) {
          final r = _rides[i];
          final isBooked = r.booked == true || r.seats == 0;
          final bg = isBooked
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35)
              : Theme.of(context).colorScheme.surface;
          final chipColor = isBooked
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary;
          final chipLabel = isBooked ? 'Booked' : 'Published';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBooked
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Theme.of(context).dividerColor.withOpacity(0.4),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              title: Row(
                children: [
                  Expanded(child: Text('${r.from} → ${r.to}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(chipLabel),
                    backgroundColor: chipColor.withOpacity(0.12),
                    side: BorderSide(color: chipColor.withOpacity(0.5)),
                    labelStyle: TextStyle(
                      color: chipColor,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _kv(context, Icons.event, df.format(r.when.toLocal())),
                    _kv(context, Icons.event_seat, 'Seats ${r.seats}'),
                    _kv(context, Icons.currency_rupee, '${r.price}'),
                    _kv(context, Icons.local_taxi, r.pool),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _rides.length,
      ),
    );
  }

  Widget _kv(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
