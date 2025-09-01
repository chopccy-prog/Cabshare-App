// lib/screens/tab_publish.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabPublish extends StatefulWidget {
  final ApiClient api;
  const TabPublish({super.key, required this.api});

  @override
  State<TabPublish> createState() => _TabPublishState();
}

class _TabPublishState extends State<TabPublish> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _seats = TextEditingController(text: '3');
  final _price = TextEditingController(text: '200');

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;

  String _pool = 'private'; // keep existing types
  bool _isCommercial = false;

  bool _busy = false;
  String? _msg;

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _pickedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _pickedTime = t);
  }

  Future<void> _publish() async {
    if (_pickedDate == null || _pickedTime == null) {
      setState(() => _msg = 'Please select date & time'); return;
    }
    setState(() { _busy = true; _msg = null; });
    try {
      final ride = await widget.api.publishRide({
        'from': _from.text.trim(),
        'to': _to.text.trim(),
        'whenDate': _fmtDate(_pickedDate!),
        'whenTime': _fmtTime(_pickedTime!),
        'seats': int.tryParse(_seats.text) ?? 1,
        'price': int.tryParse(_price.text) ?? 0,
        'pool': _pool,                 // uses existing types
        'isCommercial': _isCommercial, // backend will store if column exists; otherwise ignored
      });
      setState(() { _msg = ride == null ? 'Failed to publish' : 'Published ride ${ride['id'] ?? ''}'; });
    } catch (e) {
      setState(() { _msg = 'Error: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _pickedDate == null ? 'Pick date' : _fmtDate(_pickedDate!);
    final timeLabel = _pickedTime == null ? 'Pick time' : _fmtTime(_pickedTime!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From City'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To City'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: _pickDate,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today), const SizedBox(width: 8), Text(dateLabel),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _pickTime,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.access_time), const SizedBox(width: 8), Text(timeLabel),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _seats, decoration: const InputDecoration(labelText: 'Seats'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Ride type: '),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _pool,
              onChanged: (v) => setState(() => _pool = v ?? 'private'),
              items: const [
                DropdownMenuItem(value: 'private', child: Text('Private pool')),
                DropdownMenuItem(value: 'shared',  child: Text('Commercial pool (shared)')),
                DropdownMenuItem(value: 'private', child: Text('Commercial private')), // shown via Commercial toggle below
              ],
            ),
            const Spacer(),
            const Text('Commercial'),
            Switch(value: _isCommercial, onChanged: (v) => setState(() => _isCommercial = v)),
          ]),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _publish, child: const Text('Publish')),
          if (_msg != null) Padding(padding: const EdgeInsets.all(12), child: Text(_msg!)),
        ],
      ),
    );
  }
}
