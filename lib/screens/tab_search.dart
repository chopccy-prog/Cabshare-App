// lib/screens/tab_search.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabSearch extends StatefulWidget {
  final ApiClient api;
  const TabSearch({super.key, required this.api});

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> with SingleTickerProviderStateMixin {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _when = TextEditingController();

  bool _busy = false;
  String? _err;
  List<dynamic> _raw = []; // full server response (unfiltered)

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // optional: preload
    _search();
  }

  @override
  void dispose() {
    _tab.dispose();
    _from.dispose();
    _to.dispose();
    _when.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() { _busy = true; _err = null; });
    try {
      final items = await widget.api.searchRides(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        when: _when.text.trim().isEmpty ? null : _when.text.trim(),
      );
      setState(() { _raw = items; });
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  // ---- category filter helpers ----
  bool _isCommercial(Map<String, dynamic> m) {
    final v = m['is_commercial'];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _pool(Map<String, dynamic> m) {
    final v = m['pool'];
    if (v is String && v.isNotEmpty) return v.toLowerCase();
    // some rows may not have pool; default to 'private' so they appear somewhere
    return 'private';
  }

  // tabIndex: 0=Private pool, 1=Commercial pool, 2=Commercial private
  bool _matchCategory(Map<String, dynamic> m, int tabIndex) {
    final pool = _pool(m); // 'private' or 'shared' or maybe others in your data
    final commercial = _isCommercial(m);

    switch (tabIndex) {
      case 0: // Private pool (non-commercial private seats)
        return (pool == 'private') && !commercial;
      case 1: // Commercial pool (commercial + shared/pool)
        return (pool == 'shared') && commercial;
      case 2: // Commercial private (commercial + private)
        return (pool == 'private') && commercial;
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _filtered(int tabIndex) {
    return _raw.whereType<Map<String, dynamic>>().where((m) => _matchCategory(m, tabIndex)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // --- Search form ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (e.g., Nashik)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To (e.g., Pune)'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _when, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD, optional)'))),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ]),
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_err!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // --- Tabs ---
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Private pool'),
              Tab(text: 'Commercial pool'),
              Tab(text: 'Commercial private'),
            ],
          ),
          const Divider(height: 1),
          // --- Results per tab ---
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tab,
              children: [
                _ResultsList(items: _filtered(0)),
                _ResultsList(items: _filtered(1)),
                _ResultsList(items: _filtered(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ResultsList({required this.items});

  String _safeStr(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return '';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No rides found for this category.'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = items[i];
        final from = _safeStr(m, 'from') .isNotEmpty ? _safeStr(m, 'from')  : _safeStr(m, 'from_city');
        final to   = _safeStr(m, 'to')   .isNotEmpty ? _safeStr(m, 'to')    : _safeStr(m, 'to_city');
        final when = _safeStr(m, 'when') .isNotEmpty ? _safeStr(m, 'when')  : _safeStr(m, 'start_time');
        final price = _safeStr(m, 'price_inr').isNotEmpty ? _safeStr(m, 'price_inr') : _safeStr(m, 'price');
        final seats = _safeStr(m, 'seats') .isNotEmpty ? _safeStr(m, 'seats') : _safeStr(m, 'available_seats');
        final pool  = _safeStr(m, 'pool');
        final commercial = (m['is_commercial'] == true || m['is_commercial'] == 1 || m['is_commercial'] == 'true');

        return ListTile(
          title: Text('$from → $to'),
          subtitle: Text('When: $when • Seats: $seats • ₹$price • ${commercial ? "Commercial" : "Personal"} • ${pool.isEmpty ? "private?" : pool}'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}
