// lib/screens/tab_publish.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../data/cities.dart';

class TabPublish extends StatefulWidget {
  final ApiClient api;
  const TabPublish({super.key, required this.api});

  @override
  State<TabPublish> createState() => _TabPublishState();
}

class _TabPublishState extends State<TabPublish> {
  String? _fromCity;
  String? _toCity;
  DateTime? _date;
  TimeOfDay? _time;
  String _type = 'private_pool';
  final _seatsCtrl = TextEditingController(text: '3');
  final _priceCtrl = TextEditingController(text: '150');

  bool _submitting = false;

  @override
  void dispose() {
    _seatsCtrl.dispose();
    _priceCtrl.dispose();
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_fromCity == null || _toCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose both From and To cities')),
      );
      return;
    }
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both date and time')),
      );
      return;
    }
    final seats = int.tryParse(_seatsCtrl.text.trim());
    final price = int.tryParse(_priceCtrl.text.trim());
    if (seats == null || seats <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid seats and price')),
      );
      return;
    }

    // Merge to ISO (backend accepts either Z or local; we’ll send local ISO)
    final dt = DateTime(
      _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute,
    ).toIso8601String();

    setState(() => _submitting = true);
    try {
      await widget.api.publishRide(
        fromLocation: _fromCity!,
        toLocation: _toCity!,
        departAt: dt,
        seats: seats,
        pricePerSeatInr: price,
        rideType: _type,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride published!')),
      );
    } catch (e) {
      // Surface server error so we know exactly why a 400 happens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _cityPicker({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: kCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _typeChips() {
    const types = [
      ['private_pool', 'Private pool'],
      ['commercial_pool', 'Commercial pool'],
      ['commercial_full_car', 'Commercial Full car'],
    ];
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final selected = _type == t[0];
        return ChoiceChip(
          label: Text(t[1]),
          selected: selected,
          onSelected: (_) => setState(() => _type = t[0]),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date == null
        ? ''
        : "${_date!.year.toString().padLeft(4, '0')}-"
        "${_date!.month.toString().padLeft(2, '0')}-"
        "${_date!.day.toString().padLeft(2, '0')}";
    final timeText = _time == null
        ? ''
        : "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text('Publish ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cityPicker(label: 'From city', value: _fromCity, onChanged: (v) => setState(() => _fromCity = v)),
          const SizedBox(height: 12),
          _cityPicker(label: 'To city', value: _toCity, onChanged: (v) => setState(() => _toCity = v)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'Tap to pick',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
                  ),
                  controller: TextEditingController(text: dateText),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    hintText: 'Tap to pick',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.access_time), onPressed: _pickTime),
                  ),
                  controller: TextEditingController(text: timeText),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _typeChips(),
          const SizedBox(height: 12),
          TextField(
            controller: _seatsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Seats', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price per seat (₹)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish'),
          ),
        ],
      ),
    );
  }
}
