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
  final _seats = TextEditingController(text: '1');
  final _price = TextEditingController(text: '100');

  DateTime? _date;
  TimeOfDay? _time;
  PoolType _pool = PoolType.private;
  bool _busy = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 30),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final from = _from.text.trim();
    final to = _to.text.trim();
    final seats = int.tryParse(_seats.text.trim());
    final price = num.tryParse(_price.text.trim());

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From/To required')));
      return;
    }
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select date & time')));
      return;
    }
    if (seats == null || seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seats must be > 0')));
      return;
    }
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price must be >= 0')));
      return;
    }

    final when = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

    setState(() => _busy = true);
    try {
      await widget.api.publish(
        from: from,
        to: to,
        when: when,
        seats: seats,
        price: price,
        pool: _pool,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride published!')));
      setState(() {
        _from.clear();
        _to.clear();
        _seats.text = '1';
        _price.text = '100';
        _date = null;
        _time = null;
        _pool = PoolType.private;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Ride')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _from,
              decoration: const InputDecoration(labelText: 'From'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _to,
              decoration: const InputDecoration(labelText: 'To'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(_time == null
                        ? 'Select time'
                        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seats,
                    decoration: const InputDecoration(labelText: 'Seats'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price (INR)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PoolType>(
              value: _pool,
              decoration: const InputDecoration(labelText: 'Pool'),
              onChanged: (v) => setState(() => _pool = v ?? PoolType.private),
              items: const [
                DropdownMenuItem(value: PoolType.private, child: Text('Private pool')),
                DropdownMenuItem(value: PoolType.commercial, child: Text('Commercial pool')),
                DropdownMenuItem(value: PoolType.fullcar, child: Text('Commercial private')),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check),
              label: Text(_busy ? 'Publishing…' : 'Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
