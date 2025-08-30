// lib/features/publish/publish_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/pool_type.dart';

class PublishTab extends StatefulWidget {
  final ApiClient api;
  const PublishTab({super.key, required this.api});

  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _seats = TextEditingController(text: '1');

  DateTime? _when;
  PoolType _pool = PoolType.private;
  bool _busy = false;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _notes.dispose();
    _price.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    final from = _from.text.trim();
    final to = _to.text.trim();
    final seats = int.tryParse(_seats.text.trim()) ?? 1;
    final price = num.tryParse(_price.text.trim()) ?? 0;

    if (from.isEmpty || to.isEmpty || _when == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From, To and Date/Time are required')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.api.publish(
        from: from,
        to: to,
        when: _when!,
        seats: seats,
        price: price,
        notes: _notes.text.trim(),
        pool: _pool,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride published ✅')),
        );
      }
      _from.clear();
      _to.clear();
      _notes.clear();
      _price.text = '0';
      _seats.text = '1';
      setState(() => _when = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _from,
            decoration: const InputDecoration(labelText: 'From'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _to,
            decoration: const InputDecoration(labelText: 'To'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(_when == null
                    ? 'No time selected'
                    : _when!.toLocal().toString().substring(0, 16)),
              ),
              TextButton(onPressed: _pickDateTime, child: const Text('Pick time')),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PoolType>(
            value: _pool,
            items: PoolType.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (p) => setState(() => _pool = p ?? _pool),
            decoration: const InputDecoration(labelText: 'Pool'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _seats,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Seats'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLength: 200,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const CircularProgressIndicator() : const Text('Publish'),
          ),
        ],
      ),
    );
  }
}
