import 'package:flutter/material.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // <- not const
      appBar: AppBar(title: const Text('Inbox')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
