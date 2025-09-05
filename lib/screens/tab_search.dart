// lib/screens/tab_search.dart
//
// Allows users to search for available rides by origin, destination,
// departure date and ride type.  The ride type values correspond to
// the enum in the database: "private_pool", "commercial_pool" and
// "commercial_full".  The results list is built from the API
// response and displays basic ride details.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_client.dart';

class TabSearch extends StatefulWidget {
  final ApiClient api;
  const TabSearch({super.key, required this.api});

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  String _rideType = 'private_pool';
  bool _loading = false;
  String? _error;
  List<dynamic> _results = [];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _date = d);
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final when = _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : null;
      final rides = await widget.api.searchRides(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        when: when,
        type: _rideType,
      );
      setState(() => _results = rides);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _from,
                decoration: const InputDecoration(labelText: 'From (e.g., Nashik)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _to,
                decoration: const InputDecoration(labelText: 'To (e.g., Pune)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date (tap to pick)',
                  suffixIcon: const Icon(Icons.calendar_today),
                  hintText: _date != null
                      ? DateFormat('yyyy-MM-dd').format(_date!)
                      : '',
                ),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ride type selector for search
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'private_pool',
              icon: Icon(Icons.directions_car),
              label: Text('Private Pool'),
            ),
            ButtonSegment(
              value: 'commercial_pool',
              icon: Icon(Icons.local_taxi),
              label: Text('Commercial Pool'),
            ),
            ButtonSegment(
              value: 'commercial_full',
              icon: Icon(Icons.local_taxi),
              label: Text('Commercial Full Car'),
            ),
          ],
          selected: {_rideType},
          onSelectionChanged: (s) => setState(() => _rideType = s.first),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _search,
          child: const Text('Search'),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          )
        else if (_results.isEmpty)
            const Text('No rides found for this category.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ride = _results[index] as Map<String, dynamic>;
                final fromCity = ride['from_location'] ?? ride['from'];
                final toCity = ride['to_location'] ?? ride['to'];
                final date = ride['depart_date'] ?? '';
                final time = ride['depart_time'] ?? '';
                final price = ride['price_per_seat_inr'] ?? '';
                final seats = ride['seats_available'] ?? ride['seats'];
                return ListTile(
                  title: Text('$fromCity → $toCity'),
                  subtitle: Text('$date $time | ₹$price | Seats: $seats'),
                  onTap: () {
                    // TODO: show ride details or booking page
                  },
                );
              },
            ),
      ],
    );
  }
}