// lib/features/publish/publish_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/config_service.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});
  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _api = ApiClient(ConfigService.instance);

  final _from = TextEditingController();
  final _to = TextEditingController();
  final _driver = TextEditingController();
  final _phone = TextEditingController();
  final _car = TextEditingController();
  final _seats = TextEditingController(text: '3');
  final _price = TextEditingController(text: '200');

  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    if (_from.text.trim().isEmpty ||
        _to.text.trim().isEmpty ||
        _driver.text.trim().isEmpty ||
        _date == null ||
        _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill From, To, Driver, Date & Time')),
      );
      return;
    }
    final when = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _loading = true);
    try {
      await _api.publish(
        from: _from.text,
        to: _to.text,
        when: when, // matches ApiClient.publish signature
        seats: int.tryParse(_seats.text.trim()) ?? 0,
        price: int.tryParse(_price.text.trim()) ?? 0,
        driverName: _driver.text,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        car: _car.text.trim().isEmpty ? null : _car.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride published ✅')),
      );
      // Clear inputs
      _from.clear();
      _to.clear();
      _driver.clear();
      _phone.clear();
      _car.clear();
      _seats.text = '3';
      _price.text = '200';
      setState(() {
        _date = null;
        _time = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _from, decoration: const InputDecoration(labelText: 'From')),
          const SizedBox(height: 8),
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'To')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(_date == null ? 'Pick date' : '${_date!.year}-${_date!.month}-${_date!.day}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(_time == null ? 'Pick time' : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _driver, decoration: const InputDecoration(labelText: 'Driver name')),
          const SizedBox(height: 8),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
          const SizedBox(height: 8),
          TextField(controller: _car, decoration: const InputDecoration(labelText: 'Car (optional)')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _seats, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seats'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)'))),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish ride'),
          ),
        ],
      ),
    );
  }
}
