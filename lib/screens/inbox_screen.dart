import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class InboxScreen extends StatefulWidget {
  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final supabaseService = SupabaseService();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final data = await supabaseService.getInbox();
    setState(() => messages = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inbox')),
      body: messages.isEmpty
          ? Center(child: Text('No messages yet.'))
          : ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return ListTile(
            title: Text(msg['text'] ?? 'No text'),
            subtitle: Text('From: ${msg['sender_id']} at ${msg['ts']}'),
          );
        },
      ),
    );
  }
}