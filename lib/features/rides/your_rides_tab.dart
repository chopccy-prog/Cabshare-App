// lib/features/rides/your_rides_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api.dart';

class YourRidesTab extends StatefulWidget {
  const YourRidesTab({super.key});
  @override
  State<YourRidesTab> createState() => _YourRidesTabState();
}

class _YourRidesTabState extends State<YourRidesTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final myIds = prefs.getStringList('myRideIds') ?? <String>[];
    final all = await Api.getAllRides();
    if (myIds.isEmpty) return [];
    return all.where((r) => myIds.contains(r['id']?.toString())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Rides')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final rides = snap.data as List<Map<String, dynamic>>;
          if (rides.isEmpty) {
            return const Center(child: Text('No rides yet. Publish one!'));
          }
          return ListView.separated(
            itemCount: rides.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rides[i];
              final dt = '${r['date']} ${r['time']}';
              return ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text('${r['from']} → ${r['to']}'),
                subtitle: Text('$dt · ${r['seats']} seats · ₹${r['price']}'),
              );
            },
          );
        },
      ),
    );
  }
}
