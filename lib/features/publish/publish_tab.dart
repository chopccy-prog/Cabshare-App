import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/ride.dart';

class PublishTab extends StatefulWidget {
  final ApiClient api;
  const PublishTab({super.key, required this.api});

  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _driverName = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  final _seats = TextEditingController(text: '1');
  DateTime? _when;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _driverName.dispose();
    _phone.dispose();
    _price.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _when == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick date/time')),
      );
      return;
    }
    try {
      await widget.api.publish(
        from: _from.text.trim(),
        to: _to.text.trim(),
        when: _when!,
        driverName: _driverName.text.trim(),
        phone: _phone.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        seats: int.tryParse(_seats.text.trim()) ?? 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride published')),
      );
      _form.currentState!.reset();
      setState(() => _when = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(controller: _from, decoration: const InputDecoration(labelText: 'From'), validator: (v)=>v!.isEmpty?'Required':null),
              TextFormField(controller: _to, decoration: const InputDecoration(labelText: 'To'), validator: (v)=>v!.isEmpty?'Required':null),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(_when == null ? 'Pick date & time' : _when.toString())),
                  TextButton.icon(onPressed: _pickDateTime, icon: const Icon(Icons.event), label: const Text('Pick'))
                ],
              ),
              TextFormField(controller: _driverName, decoration: const InputDecoration(labelText: 'Driver name'), validator: (v)=>v!.isEmpty?'Required':null),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v)=>v!.isEmpty?'Required':null),
              TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
              TextFormField(controller: _seats, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seats')),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Publish')),
            ],
          ),
        ),
      ),
    );
  }
}
