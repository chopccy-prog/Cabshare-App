// lib/features/publish/publish_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});
  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 1;
  int _price = 0;
  bool _busy = false;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date!);
      final timeStr = _time!.format(context); // e.g. 10:30 AM; backend accepts "10:30" so normalize:
      final time24 = _to24h(_time!);

      final created = await Api.postRide({
        'from': _from.text.trim(),
        'to': _to.text.trim(),
        'date': dateStr,
        'time': time24,
        'seats': _seats,
        'price': _price,
      });

      // Save ride id locally so "Your Rides" can find it
      final id = created['id']?.toString();
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        final ids = prefs.getStringList('myRideIds') ?? <String>[];
        if (!ids.contains(id)) {
          ids.add(id);
          await prefs.setStringList('myRideIds', ids);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride published ✅')),
        );
        _form.currentState!.reset();
        setState(() {
          _date = null;
          _time = null;
          _seats = 1;
          _price = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _to24h(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt); // "10:30"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Ride')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                TextFormField(
                  controller: _from,
                  decoration: const InputDecoration(labelText: 'From'),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _to,
                  decoration: const InputDecoration(labelText: 'To'),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(_date == null
                            ? 'Pick date'
                            : DateFormat('EEE, d MMM yyyy').format(_date!)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _pickDate,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time'),
                        subtitle: Text(_time == null ? 'Pick time' : _time!.format(context)),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: _pickTime,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _seats,
                        items: [1, 2, 3, 4, 5, 6]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e seats')))
                            .toList(),
                        onChanged: (v) => setState(() => _seats = v ?? 1),
                        decoration: const InputDecoration(labelText: 'Seats'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                        onChanged: (v) => _price = int.tryParse(v) ?? 0,
                        validator: (v) =>
                        (int.tryParse(v ?? '') ?? -1) < 0 ? 'Enter valid price' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(_busy ? 'Publishing…' : 'Publish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
