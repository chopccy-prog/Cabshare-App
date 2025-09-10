// lib/screens/tab_my_rides.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabMyRides extends StatefulWidget {
  final ApiClient api;
  const TabMyRides({super.key, required this.api});

  @override
  State<TabMyRides> createState() => _TabMyRidesState();
}

class _TabMyRidesState extends State<TabMyRides> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>> _loadPublished() => widget.api.myPublishedRides();
  Future<List<Map<String, dynamic>>> _loadBooked()    => widget.api.myBookings();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cabshare'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Published'),
            Tab(text: 'Booked'),
          ]),
        ),
        body: TabBarView(children: [
          _ListFuture(future: _loadPublished(), render: _rideTile),
          _ListFuture(future: _loadBooked(), render: _bookingTile),
        ]),
      ),
    );
  }

  Widget _rideTile(Map<String, dynamic> r) {
    final dt = DateTime.tryParse(r['departure_at'] ?? '')?.toLocal();
    final when = dt == null ? '' : '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    return ListTile(
      title: Text('${r['from_city']} → ${r['to_city']}'),
      subtitle: Text('$when | ${r['status']} | Seats: ${r['seats_available']}'),
    );
  }

  Widget _bookingTile(Map<String, dynamic> b) {
    final ride = b['rides'] ?? {};
    final dt = DateTime.tryParse(ride['departure_time'] ?? ride['departure_at'] ?? '')?.toLocal();
    final when = dt == null ? '' : '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    return ListTile(
      title: Text('${ride['route_id'] ?? ''} • ${b['status']}'),
      subtitle: Text('Seats: ${b['seats_booked'] ?? 0} • On $when'),
      trailing: Text('₹${b['fare_total_inr'] ?? 0}'),
    );
  }
}

class _ListFuture extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final Widget Function(Map<String, dynamic>) render;
  const _ListFuture({required this.future, required this.render});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (c, snap) {
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load: ${snap.error}', style: const TextStyle(color: Colors.red)),
          ));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data!;
        if (data.isEmpty) return const Center(child: Text('No items yet'));
        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) => render(data[i]),
        );
      },
    );
  }
}
