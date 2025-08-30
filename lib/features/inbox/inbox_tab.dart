import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class InboxTab extends StatelessWidget {
  final ApiClient api;
  final String currentUser;
  const InboxTab({super.key, required this.api, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Placeholder until we wire real chat
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64),
            const SizedBox(height: 12),
            Text('Hello $currentUser'),
            const SizedBox(height: 4),
            const Text('1:1 messages will appear here soon.'),
          ],
        ),
      ),
    );
  }
}
