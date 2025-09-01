// lib/features/search/search_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/ride.dart';
import '../../models/pool_type.dart';

class SearchTab extends StatefulWidget {
  final ApiClient api;
  const SearchTab({super.key, required this.api});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> with SingleTickerProviderStateMixin {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  bool _busy = false;
  List<Ride> _results = [];

  late final TabController _tab;
  PoolType get _currentPool {
    switch (_tab.index) {
      case 0: return PoolType.private;
      case 1: return PoolType.commercial;
      case 2: return PoolType.fullcar;
      default: return PoolType.private;
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final list = await widget.api.search(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        date: _date,
        pool: _currentPool,
      );
      if (!mounted) return;
      setState(() => _results = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _book(String id) async {
    setState(() => _busy = true);
    try {
      await widget.api.book(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booked!')));
      await _search(); // refresh seats
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Private pool'),
            Tab(text: 'Commercial pool'),
            Tab(text: 'Commercial private'),
          ],
          onTap: (_) {}, // pool type changes via index
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _from,
                    decoration: const InputDecoration(labelText: 'From'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _to,
                    decoration: const InputDecoration(labelText: 'To'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          child: Text(_date == null
                              ? 'Select date'
                              : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _busy ? null : _search,
                        icon: const Icon(Icons.search),
                        label: Text(_busy ? 'Searching…' : 'Search'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  final d = r.when;
                  final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    title: Text('${r.from} → ${r.to}'),
                    subtitle: Text('$date  $time  • ₹${r.price}  • seats: ${r.seats}  • ${r.pool}'),
                    trailing: FilledButton(
                      onPressed: _busy ? null : () => _book(r.id),
                      child: const Text('Book'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
