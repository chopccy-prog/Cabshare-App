// lib/screens/tab_my_rides.dart
//
// Displays rides created by the current user (driver role) and rides they
// have booked (rider role).  Uses the ApiClient to fetch rides and
// passes the current user's UID as a query parameter so the backend
// can properly filter and authorize requests.  The UI toggles
// between "Published" and "Booked" via a SegmentedButton.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';

class TabMyRides extends StatefulWidget {
  final ApiClient api;
  const TabMyRides({super.key, required this.api});

  @override
  State<TabMyRides> createState() => _TabMyRidesState();
}

class _TabMyRidesState extends State<TabMyRides> {
  bool _showPublished = true;
  bool _loading = true;
  String? _error;
  List<dynamic> _published = [];
  List<dynamic> _booked = [];

  @override
  void initState() {
    super.initState();
    _refreshRides();
  }

  Future<void> _refreshRides() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final published = await widget.api.myRides(role: 'driver', uid: userId);
      final booked = await widget.api.myRides(role: 'rider', uid: userId);
      setState(() {
        _published = published;
        _booked = booked;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rides = _showPublished ? _published : _booked;
    return Column(
      children: [
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Published')),
            ButtonSegment(value: false, label: Text('Booked')),
          ],
          selected: {_showPublished},
          onSelectionChanged: (s) => setState(() => _showPublished = s.first),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
              : rides.isEmpty
              ? const Center(child: Text('No rides found'))
              : ListView.separated(
            itemCount: rides.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ride = rides[index] as Map<String, dynamic>;
              final fromCity = ride['from_location'] ?? ride['from'];
              final toCity = ride['to_location'] ?? ride['to'];
              final date = ride['depart_date'] ?? '';
              final time = ride['depart_time'] ?? '';
              final seats = ride['seats_total'] ?? ride['seats'] ?? '';
              return ListTile(
                title: Text('$fromCity → $toCity'),
                subtitle: Text('$date $time | Seats: $seats'),
                onTap: () {
                  // TODO: navigate to ride details or chat
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _refreshRides,
            child: const Text('Refresh'),
          ),
        ),
      ],
    );
  }
}