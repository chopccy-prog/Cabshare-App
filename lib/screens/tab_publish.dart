import 'package:flutter/material.dart';
import '../services/api_client.dart';

enum RideCategory { privatePool, commercialPool, commercialFullCar }

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

  RideCategory _cat = RideCategory.privatePool;

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}";

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context, initialDate: _pickedDate ?? now,
        firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (d != null) setState(() => _pickedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _pickedTime ?? TimeOfDay.now());
    if (t != null) setState(() => _pickedTime = t);
  }

  // map category -> pool/isCommercial
  (String pool, bool isCommercial) _mapCat() {
    switch (_cat) {
      case RideCategory.privatePool:       return ('shared',  false);
      case RideCategory.commercialPool:    return ('shared',  true);
      case RideCategory.commercialFullCar: return ('private', true);
    }
  }

  Future<void> _publish() async {
    if (_pickedDate == null || _pickedTime == null) {
      _snack('Please select date & time'); return;
    }
    final (pool, isCommercial) = _mapCat();
    try {
      final ride = await widget.api.publishRide({
        'from': _from.text.trim(),
        'to': _to.text.trim(),
        'whenDate': _fmtDate(_pickedDate!),
        'whenTime': _fmtTime(_pickedTime!),
        'seats': int.tryParse(_seats.text) ?? 1,
        'price': int.tryParse(_price.text) ?? 0,
        'pool': pool,
        'isCommercial': isCommercial,
      });
      _snack(ride == null ? 'Failed to publish' : 'Published!');
    } catch (e) {
      _snack('Error: $e');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final dateLabel = _pickedDate == null ? 'Pick date' : _fmtDate(_pickedDate!);
    final timeLabel = _pickedTime == null ? 'Pick time' : _fmtTime(_pickedTime!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Text('Ride category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<RideCategory>(
            segments: const [
              ButtonSegment(value: RideCategory.privatePool,       icon: Icon(Icons.directions_car), label: Text('Private Pool')),
              ButtonSegment(value: RideCategory.commercialPool,    icon: Icon(Icons.local_taxi),    label: Text('Commercial Pool')),
              ButtonSegment(value: RideCategory.commercialFullCar, icon: Icon(Icons.local_taxi),    label: Text('Commercial Full Car')),
            ],
            selected: {_cat},
            onSelectionChanged: (s) => setState(() => _cat = s.first),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _publish, child: const Text('Publish')),
        ],
      ),
    );
  }
}
