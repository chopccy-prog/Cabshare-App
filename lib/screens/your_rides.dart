// lib/screens/your_rides.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class YourRidesScreen extends StatefulWidget {
  const YourRidesScreen({super.key});

  @override
  State<YourRidesScreen> createState() => _YourRidesScreenState();
}

class _YourRidesScreenState extends State<YourRidesScreen> {
  final _client = Supabase.instance.client;
  final _fmt = DateFormat('dd MMM, hh:mm a');
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _client.auth.currentUser!.id;

      final data = await _client
          .from('bookings')
          .select('id, status, seats, created_at, ride_id')
          .eq('rider_id', uid)
          .order('created_at', ascending: false);

      setState(() => _rows = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Rides')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load rides:\n$_error',
                style: const TextStyle(color: Colors.red)),
          ),
        ])
            : _rows.isEmpty
            ? const Center(child: Text('No rides yet'))
            : ListView.separated(
          itemCount: _rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = _rows[i];
            final status =
            (r['status'] ?? 'pending').toString().toUpperCase();
            final when = DateTime.tryParse(r['created_at'] ?? '');
            final created =
            when == null ? '' : _fmt.format(when.toLocal());

            return ListTile(
              title: Text('Booking #${r['id'].toString().substring(0, 8)}'),
              subtitle: Text('Created: $created • Seats: ${r['seats'] ?? '-'}'),
              trailing: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: status == 'CONFIRMED'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: status == 'CONFIRMED'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'CONFIRMED'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
