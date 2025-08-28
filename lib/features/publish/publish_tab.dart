import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});
  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _api = ApiClient();

  final _driver = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _price = TextEditingController();
  final _seats = TextEditingController(text: '1');
  final _car = TextEditingController();

  DateTime? _when;
  bool _loading = false;

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _when ?? DateTime.now(),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    final driver = _driver.text.trim();
    final from = _from.text.trim();
    final to = _to.text.trim();
    if (driver.isEmpty || from.isEmpty || to.isEmpty || _when == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver, from, to and when are required')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.publish(
        driverName: driver,
        from: from,
        to: to,
        when: _when!,
        price: int.tryParse(_price.text.trim()) ?? 0,
        seats: int.tryParse(_seats.text.trim()) ?? 1,
        car: _car.text.trim().isEmpty ? null : _car.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride published')));
      _price.clear();
      _seats.text = '1';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _driver, decoration: const InputDecoration(labelText: 'Driver name')),
          const SizedBox(height: 12),
          TextField(controller: _from, decoration: const InputDecoration(labelText: 'From city')),
          const SizedBox(height: 12),
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'To city')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(_when == null ? 'When: (tap Pick)' : 'When: $_when')),
              OutlinedButton(onPressed: _pickWhen, child: const Text('Pick')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
          const SizedBox(height: 12),
          TextField(controller: _seats, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seats')),
          const SizedBox(height: 12),
          TextField(controller: _car, decoration: const InputDecoration(labelText: 'Car (optional)')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loading ? null : _submit, child: const Text('Publish')),
        ],
      ),
    );
  }
}
