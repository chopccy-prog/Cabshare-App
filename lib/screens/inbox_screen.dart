// lib/screens/inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _client = Supabase.instance.client;
  final _fmt = DateFormat('dd MMM, hh:mm a');

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _threads = [];

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
          .from('v_inbox_threads')
          .select('*')
          .or('rider_id.eq.$uid,driver_id.eq.$uid')
          .order('ride_created_at', ascending: false);

      setState(() => _threads = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load inbox:\n$_error',
                style: const TextStyle(color: Colors.red)),
          ),
        ])
            : _threads.isEmpty
            ? const Center(child: Text('No conversations yet'))
            : ListView.separated(
          itemCount: _threads.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final t = _threads[i];
            final isDriver =
                t['driver_id'] == _client.auth.currentUser!.id;
            final otherName = isDriver
                ? (t['rider_name'] ?? 'Rider')
                : (t['driver_name'] ?? 'Driver');
            final when = DateTime.tryParse(t['ride_created_at'] ?? '');
            final created =
            when == null ? '' : _fmt.format(when.toLocal());

            return ListTile(
              title: Text(otherName),
              subtitle: Text('Ride • $created'),
              trailing: Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary),
              onTap: () {
                // If you add a Thread screen later, pass t['thread_id'] here
                // Navigator.pushNamed(context, '/inbox/thread', arguments: t['thread_id']);
              },
            );
          },
        ),
      ),
    );
  }
}
