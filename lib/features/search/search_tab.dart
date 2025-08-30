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
  List<Ride> _results = [];
  bool _loading = false;
  late TabController _tabController;

  PoolType get _currentPool {
    switch (_tabController.index) {
      case 0: return PoolType.privatePool;
      case 1: return PoolType.commercialPool;
      case 2: return PoolType.commercialPrivate;
      default: return PoolType.privatePool;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _doSearch() async {
    setState(() => _loading = true);
    try {
      final list = await widget.api.search(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to: _to.text.trim().isEmpty ? null : _to.text.trim(),
        date: _date,
        pool: _currentPool,
      );
      setState(() => _results = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _book(String id) async {
    try {
      await widget.api.book(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booked! Driver will contact you.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search rides'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Private pool'),
            Tab(text: 'Commercial pool'),
            Tab(text: 'Commercial private'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (_) => _buildSearchPanel()),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_date == null ? 'Pick date' : _date!.toString().substring(0, 10)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _doSearch,
                icon: const Icon(Icons.search),
                label: Text(_loading ? 'Searching…' : 'Search'),
              ),
            ),
          ]),
          const Divider(height: 24),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No rides yet.'))
                : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = _results[i];
                return Card(
                  child: ListTile(
                    title: Text('${r.from} → ${r.to}'),
                    subtitle: Text('${r.when.toLocal()} • ₹${r.price} • seats ${r.seats}'),
                    trailing: FilledButton(
                      onPressed: () => _book(r.id),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
