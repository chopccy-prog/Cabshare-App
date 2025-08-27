// lib/features/publish/publish_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';

class PublishTab extends StatefulWidget {
  const PublishTab({super.key});
  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _form = GlobalKey<FormState>();
  final _driverCtrl = TextEditingController(text: 'You');
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '199');
  final _seatsCtrl = TextEditingController(text: '2');
  final _carCtrl = TextEditingController(text: 'Sedan');
  DateTime _when = DateTime.now().add(const Duration(hours: 2));
  bool _submitting = false;

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.I.publishRide(
        driverName: _driverCtrl.text.trim(),
        fromCity: _fromCtrl.text.trim(),
        toCity: _toCtrl.text.trim(),
        when: _when,
        price: int.parse(_priceCtrl.text.trim()),
        seats: int.parse(_seatsCtrl.text.trim()),
        car: _carCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride published')));
      }
      _form.currentState!.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('EEE, d MMM h:mm a').format(_when);
    return Scaffold(
      appBar: AppBar(title: const Text('Publish ride')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _driverCtrl,
              decoration: const InputDecoration(labelText: 'Driver name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fromCtrl,
              decoration: const InputDecoration(labelText: 'From city', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _toCtrl,
              decoration: const InputDecoration(labelText: 'To city', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('When: $ts')),
                FilledButton.tonal(onPressed: _pickDateTime, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seatsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Seats', border: OutlineInputBorder()),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carCtrl,
              decoration: const InputDecoration(labelText: 'Car (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? const CircularProgressIndicator() : const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
