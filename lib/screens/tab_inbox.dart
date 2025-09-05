// lib/screens/tab_inbox.dart
//
// This screen shows the user's active conversations and allows them to
// open a chat when tapping on a conversation.  It fetches the inbox
// via ApiClient.inbox() passing the current user's UID so the backend
// can authorize the request.  If the bearer token is set on the
// ApiClient the uid parameter may not be required, but including it
// makes the endpoint work in debug mode without authorization headers.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';

class TabInbox extends StatefulWidget {
  final ApiClient api;
  const TabInbox({super.key, required this.api});

  @override
  State<TabInbox> createState() => _TabInboxState();
}

class _TabInboxState extends State<TabInbox> {
  late Future<List<dynamic>> _inboxFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inboxFuture = _loadInbox();
  }

  Future<List<dynamic>> _loadInbox() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final conversations = await widget.api.inbox(uid: user?.id);
      return conversations;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _inboxFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No conversations found'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            // Expect the backend to return a "ride" with aliases for legacy fields
            final ride = item['ride'] as Map<String, dynamic>;
            final fromCity = ride['from_location'] ?? ride['from'];
            final toCity = ride['to_location'] ?? ride['to'];
            final title = '$fromCity → $toCity';
            return ListTile(
              title: Text(title),
              subtitle: Text('Messages: ${item['message_count'] ?? 0}'),
              onTap: () {
                // TODO: Navigate to chat screen with rideId and otherUserId
              },
            );
          },
        );
      },
    );
  }
}