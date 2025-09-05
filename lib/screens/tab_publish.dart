// lib/screens/tab_publish.dart
//
// This widget allows a driver to publish a new ride.  It collects the
// origin, destination, date, time, number of seats, price per seat and
// ride type.  Once the user taps "Publish" the form values are sent to
// the backend via the ApiClient.  The backend requires the `ride_type`
// to be one of `private_pool`, `commercial_pool` or `commercial_full`,
// which correspond to the three ride options offered by the app.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';

class TabPublish extends StatefulWidget {
  final ApiClient api;
  const TabPublish({super.key, required this.api});

  @override
  State<TabPublish> createState() => _TabPublishState();
}

class _TabPublishState extends State<TabPublish> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _seats = TextEditingController(text: '1');
  final _price = TextEditingController(text: '0');

  // The ride type must match the enum defined in the database.  See
  // schema.sql for `rides_ride_type_check`: values are
  // "private_pool", "commercial_pool" and "commercial_full".
  String _rideType = 'private_pool';
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _date.dispose();
    _time.dispose();
    _seats.dispose();
    _price.dispose();
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
      _date.text =
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      _time.text =
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _publish() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      if (_from.text.trim().isEmpty ||
          _to.text.trim().isEmpty ||
          _date.text.trim().isEmpty) {
        throw Exception('Missing required fields');
      }
      final seats = int.tryParse(_seats.text) ?? 1;
      final price = int.tryParse(_price.text) ?? 0;

      // Combine date and time.  If no time is provided, use date only.
      final departAt = _time.text.isNotEmpty
          ? '${_date.text.trim()} ${_time.text.trim()}'
          : _date.text.trim();

      await widget.api.publishRide(
        fromLocation: _from.text.trim(),
        toLocation: _to.text.trim(),
        departAt: departAt,
        seats: seats,
        pricePerSeatInr: price,
        rideType: _rideType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride published')),
      );
      // Reset form fields for the next entry
      _from.clear();
      _to.clear();
      _date.clear();
      _time.clear();
      _seats.text = '1';
      _price.text = '0';
      setState(() => _rideType = 'private_pool');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
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
                decoration: const InputDecoration(labelText: 'From City'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _to,
                decoration: const InputDecoration(labelText: 'To City'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _date,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _time,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:mm)',
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _seats,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seats'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'Price (₹/seat)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Ride type selector using allowed values
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
          onSelectionChanged: (s) =>
              setState(() => _rideType = s.first),
        ),
        const SizedBox(height: 16),
        if (_err != null)
          Text(
            _err!,
            style: const TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _publish,
          child: const Text('Publish'),
        ),
      ],
    );
  }
}