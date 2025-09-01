import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TabInbox extends StatefulWidget {
  final ApiClient api;
  const TabInbox({super.key, required this.api});
  @override
  State<TabInbox> createState() => _TabInboxState();
}

class _TabInboxState extends State<TabInbox> {
  bool _busy = false;
  String? _err;
  List<dynamic> _threads = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _busy = true; _err = null; });
    try {
      final items = await widget.api.inbox();
      setState(() => _threads = items);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    if (_err != null) return Center(child: Text(_err!, style: const TextStyle(color: Colors.red)));
    if (_threads.isEmpty) return const Center(child: Text('No conversations yet.'));

    return ListView.separated(
      itemCount: _threads.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = _threads[i] as Map<String,dynamic>;
        final other = (t['other_user_id'] ?? '').toString();
        final last = (t['last_text'] ?? '').toString();
        final rideId = (t['ride_id'] ?? '').toString();
        return ListTile(
          title: Text('Chat with $other'),
          subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _ChatPage(api: widget.api, rideId: rideId, otherUserId: other),
          )),
        );
      },
    );
  }
}

class _ChatPage extends StatefulWidget {
  final ApiClient api;
  final String rideId;
  final String otherUserId;
  const _ChatPage({required this.api, required this.rideId, required this.otherUserId});
  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _text = TextEditingController();
  List<dynamic> _msgs = [];
  bool _busy = false;

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final items = await widget.api.messages(widget.rideId, widget.otherUserId);
      setState(() => _msgs = items);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final txt = _text.text.trim();
    if (txt.isEmpty) return;
    await widget.api.sendMessage(widget.rideId, widget.otherUserId, txt);
    _text.clear();
    await _load();
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i] as Map<String,dynamic>;
                final mine = m['sender_id'] == me;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: mine ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text((m['text'] ?? '').toString()),
                  ),
                );
              },
            ),
          ),
          Row(children: [
            Expanded(child: TextField(controller: _text, decoration: const InputDecoration(contentPadding: EdgeInsets.all(12), hintText: 'Message'))),
            IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ]),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
