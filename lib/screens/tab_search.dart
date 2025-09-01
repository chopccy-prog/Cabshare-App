// lib/screens/tab_search.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabSearch extends StatefulWidget {
  final ApiClient api;
  const TabSearch({super.key, required this.api});

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _when = TextEditingController();
  List<dynamic> _items = [];
  bool _busy = false;

  Future<void> _search() async {
    setState(() { _busy = true; });
    try {
      final items = await widget.api.searchRides(
        from: _from.text.isEmpty ? null : _from.text,
        to: _to.text.isEmpty ? null : _to.text,
        when: _when.text.isEmpty ? null : _when.text,
      );
      setState(() { _items = items; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From City'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To City'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _when, decoration: const InputDecoration(labelText: 'Date YYYY-MM-DD'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _search, child: const Text('Search')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final it = _items[i] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text('${it['from_city']} → ${it['to_city']}'),
                          subtitle: Text('${it['date'] ?? it['when']} | ₹${it['price_inr'] ?? '--'} | seats ${it['seats_available'] ?? ''}'),
                          trailing: FilledButton(
                            onPressed: (){},
                            child: const Text('View'),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
