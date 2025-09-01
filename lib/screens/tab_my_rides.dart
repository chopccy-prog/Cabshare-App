// lib/screens/tab_my_rides.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabMyRides extends StatefulWidget {
  final ApiClient api;
  const TabMyRides({super.key, required this.api});

  @override
  State<TabMyRides> createState() => _TabMyRidesState();
}

class _TabMyRidesState extends State<TabMyRides> {
  String _role = 'driver';
  List<dynamic> _items = [];
  bool _busy = false;

  Future<void> _load() async {
    setState(() { _busy = true; });
    try {
      final items = await widget.api.myRides(_role);
      setState(() { _items = items; });
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
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            const Text('Role:'),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'driver', child: Text('Driver')),
                DropdownMenuItem(value: 'rider', child: Text('Rider')),
              ],
              onChanged: (v) => setState(() { _role = v!; _load(); }),
            ),
            const Spacer(),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const Divider(),
        Expanded(
          child: _busy ? const Center(child: CircularProgressIndicator()) :
          ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final it = _items[i] as Map<String, dynamic>;
              return ListTile(
                title: Text('${it['route']?['code'] ?? it['id']}'),
                subtitle: Text('${it['created_at'] ?? ''}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
