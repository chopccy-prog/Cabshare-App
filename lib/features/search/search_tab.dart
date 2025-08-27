import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart'; // your API client with baseUrl + fetch logic
import 'widgets/ride_tile.dart';
import 'ride_details_page.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime? _date;

  bool _loading = false;
  List<Ride> _results = [];
  String? _error;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      initialDate: _date ?? now,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rides = await Api.searchRides(
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
        date: _date, // nullable; API can treat null as “any date”
      );
      setState(() {
        _results = rides;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
    _date == null ? 'Any date' : DateFormat('EEE, d MMM').format(_date!);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search rides'),
        ),
        body: Column(
          children: [
            // Search form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _fromCtrl,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _toCtrl,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(dateLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: const Icon(Icons.search),
                        label:
                        Text(_loading ? 'Searching…' : 'Search'),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Results list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final ride = _results[i];
                  return RideTile(
                    ride: ride,
                    onTap: () async {
                      // open details -> can book from there
                      final booked = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RideDetailsPage(ride: ride),
                        ),
                      );
                      // if booked, reflect locally (optional)
                      if (booked == true && mounted) {
                        setState(() {
                          _results[i] =
                              ride.copyWith(spots: ride.spots - 1);
                        });
                      }
                    },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 48),
            const SizedBox(height: 8),
            Text(
              'No rides yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing date or swapping From/To',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
