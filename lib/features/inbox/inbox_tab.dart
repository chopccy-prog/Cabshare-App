// lib/features/inbox/inbox_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'chat_screen.dart';

class InboxTab extends StatefulWidget {
  final ApiClient api;
  final String currentUser; // e.g. 'rider'
  const InboxTab({super.key, required this.api, required this.currentUser});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _busy = false;
  List<Map<String, dynamic>> _convs = [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final list = await widget.api.getConversations(user: widget.currentUser);
      if (!mounted) return;
      setState(() => _convs = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inbox load failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _convs.isEmpty
          ? const Center(child: Text('No conversations yet'))
          : ListView.separated(
        itemCount: _convs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = _convs[i];
          final title = (c['title'] ?? 'Conversation').toString();
          final lastText = (c['lastText'] ?? '').toString();
          final id = (c['id'] ?? '').toString();
          return ListTile(
            title: Text(title),
            subtitle: Text(lastText.isEmpty ? ' ' : lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(api: widget.api, conversationId: id, me: widget.currentUser),
            )),
          );
        },
      ),
    );
  }
}
