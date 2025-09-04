import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InboxScreen extends StatefulWidget {
  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final supabase = Supabase.instance.client;
  final String testUserId = '00000000-0000-0000-0000-000000000000'; // Replace with your test user's UUID

  List<dynamic> messages = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await supabase
          .from('messages') // Assume table name; adjust per schema
          .select('*')
          .or('sender_id.eq.$testUserId,receiver_id.eq.$testUserId'); // Fixed: Use UUID instead of 'Inbox'

      setState(() {
        messages = response;
        isLoading = false;
      });
    } catch (e) {
      setState() {
        errorMessage = e.toString();
        isLoading = false;
      });
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cabshare')),
      body: Column(
        children: [
          if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
          if (isLoading) Center(child: CircularProgressIndicator()),
          if (!isLoading && messages.isEmpty) Center(child: Text('No messages yet.')),
          // Add ListView.builder to display messages
        ],
      ),
    );
  }
}