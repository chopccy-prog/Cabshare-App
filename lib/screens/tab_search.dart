import 'package:flutter/material.dart';
import '../services/api_client.dart';

enum RideCategory { privatePool, commercialPool, commercialFullCar }

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
  DateTime? _pickedDate;

  RideCategory _cat = RideCategory.privatePool;

  bool _busy = false;
  String? _err;
  List<dynamic> _items = [];

  @override
  void dispose() {
    _from.dispose(); _to.dispose(); _when.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context, initialDate: _pickedDate ?? now,
        firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (d != null) {
      _pickedDate = d;
      _when.text = "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
      setState(() {});
    }
  }

  // client-side match identical to publish mapping
  bool _matchCategory(Map<String, dynamic> m) {
    final isCommercial = (m['is_commercial'] == true || m['is_commercial'] == 1 || m['is_commercial'] == 'true');
    final pool = (m['pool'] ?? '').toString().toLowerCase();

    switch (_cat) {
      case RideCategory.privatePool:       return !isCommercial && pool == 'shared';
      case RideCategory.commercialPool:    return  isCommercial && pool == 'shared';
      case RideCategory.commercialFullCar: return  isCommercial && pool == 'private';
    }
  }

  Future<void> _search() async {
    setState(() { _busy = true; _err = null; });
    try {
      final items = await widget.api.searchRides(
        from: _from.text.trim().isEmpty ? null : _from.text.trim(),
        to:   _to.text.trim().isEmpty   ? null : _to.text.trim(),
        when: _when.text.trim().isEmpty ? null : _when.text.trim(),
      );
      setState(() => _items = items.whereType<Map<String,dynamic>>().where(_matchCategory).toList());
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From (e.g., Nashik)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To (e.g., Pune)'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _when,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Date (tap to pick)', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _busy ? null : _search, icon: const Icon(Icons.search), label: const Text('Search')),
              ]),
              if (_err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err!, style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<RideCategory>(
            segments: const [
              ButtonSegment(value: RideCategory.privatePool,       icon: Icon(Icons.directions_car), label: Text('Private Pool')),
              ButtonSegment(value: RideCategory.commercialPool,    icon: Icon(Icons.local_taxi),    label: Text('Commercial Pool')),
              ButtonSegment(value: RideCategory.commercialFullCar, icon: Icon(Icons.local_taxi),    label: Text('Commercial Full Car')),
            ],
            selected: {_cat},
            onSelectionChanged: (s) => setState(() => _cat = s.first),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : (_items.isEmpty
              ? const Center(child: Text('No rides found for this category.'))
              : ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = _items[i] as Map<String,dynamic>;
              final from  = (m['from'] ?? '').toString();
              final to    = (m['to'] ?? '').toString();
              final when  = (m['start_time'] ?? m['when'] ?? '').toString();
              final price = (m['price_inr'] ?? m['price'] ?? '').toString();
              final seats = (m['seats'] ?? m['available_seats'] ?? '').toString();
              return ListTile(
                title: Text('$from → $to'),
                subtitle: Text('When: $when • Seats: $seats • ₹$price'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          )),
        ),
      ],
    );
  }
}
