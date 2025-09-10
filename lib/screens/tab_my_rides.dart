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
  late Future<List<Map<String, dynamic>>> _pubFut;
  late Future<List<Map<String, dynamic>>> _bookFut;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _pubFut = widget.api.myPublishedRides();
    _bookFut = widget.api.myBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your rides')),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refresh),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Published by you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _pubFut,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return const ListTile(
                    title: Text('No published rides yet.'),
                    subtitle: Text('Publish a ride to see it here.'),
                  );
                }
                return Column(children: list.map(_rideTile).toList());
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Your bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _bookFut,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return const ListTile(
                    title: Text('No bookings yet.'),
                    subtitle: Text('Book a seat to see it here.'),
                  );
                }
                return Column(children: list.map(_bookingTile).toList());
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _rideTile(Map<String, dynamic> ride) {
    final from = ride['from_location'] ?? ride['from_city'] ?? '-';
    final to = ride['to_location'] ?? ride['to_city'] ?? '-';
    final dt = ride['depart_at'] ?? ride['departure_at'] ?? '';
    return Card(
      child: ListTile(
        title: Text('$from → $to'),
        subtitle: Text('Departure: $dt'),
      ),
    );
    // (Tap to open detail if you want; skipping to keep minimal)
  }

  Widget _bookingTile(Map<String, dynamic> b) {
    // Try to find nested ride fields; otherwise show ids
    final r = b['rides'] ?? b['ride'] ?? {};
    final from = r['from_location'] ?? r['from_city'] ?? '-';
    final to = r['to_location'] ?? r['to_city'] ?? '-';
    final dt = r['depart_at'] ?? r['departure_at'] ?? '';
    final status = (b['status'] ?? '').toString();
    return Card(
      child: ListTile(
        title: Text('$from → $to'),
        subtitle: Text('Departure: $dt\nStatus: $status'),
        isThreeLine: true,
      ),
    );
  }
}
