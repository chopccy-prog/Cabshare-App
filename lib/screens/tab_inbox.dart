// lib/screens/tab_inbox.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabInbox extends StatefulWidget {
  final ApiClient api;
  const TabInbox({super.key, required this.api});

  @override
  State<TabInbox> createState() => _TabInboxState();
}

class _TabInboxState extends State<TabInbox> {
  List<dynamic> _convos = [];
  bool _busy = false;

  Future<void> _load() async {
    setState(() { _busy = true; });
    try {
      _convos = await widget.api.inbox();
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _busy ? const Center(child: CircularProgressIndicator()) :
      ListView.builder(
        itemCount: _convos.length,
        itemBuilder: (context, i) {
          final it = _convos[i] as Map<String, dynamic>;
          return ListTile(
            title: Text(it['title'] ?? 'Conversation'),
            subtitle: Text(it['last_text'] ?? ''),
          );
        },
      );
  }
}
