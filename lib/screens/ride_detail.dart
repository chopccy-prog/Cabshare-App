import 'package:flutter/material.dart';
import '../services/api_client.dart';

class RideDetail extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> ride;
  const RideDetail({super.key, required this.api, required this.ride});

  @override
  State<RideDetail> createState() => _RideDetailState();
}

class _RideDetailState extends State<RideDetail> {
  List<Map<String, dynamic>> _stops = [];
  String? _fromStopId;
  String? _toStopId;
  int _seats = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stops = await widget.api.getRouteStops(widget.ride['route_id']);
      setState(() {
        _stops = stops;
        if (stops.isNotEmpty) {
          _fromStopId = stops.first['stop_id'] ?? stops.first['id'];
          _toStopId = stops.length > 1
              ? (stops.last['stop_id'] ?? stops.last['id'])
              : (stops.first['stop_id'] ?? stops.first['id']);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _book() async {
    if (_fromStopId == null || _toStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and drop stops')),
      );
      return;
    }

    try {
      final uid = await _whoAmI(); // replace with your auth user id getter
      final pricePerSeat = (widget.ride['price_inr'] ?? 0) as num;

      await widget.api.createBooking(
        rideId: widget.ride['id'],
        riderId: uid,
        fromStopId: _fromStopId!,
        toStopId: _toStopId!,
        seats: _seats,
        pricePerSeatInr: pricePerSeat,
        depositInr: 0,        // safe default; change if you take deposits
        autoApprove: false,   // driver can toggle later if you add that
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking requested')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    }
  }

  Future<String> _whoAmI() async {
    // TODO: wire your auth. For now expect backend to accept the JWT bearer
    // and resolve it; or pass Supabase user id if you keep it on client.
    // If you already store uid in memory, return that here.
    throw Exception('Implement auth uid provider');
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final from = ride['from_city'] ?? ride['from'] ?? 'unknown';
    final to = ride['to_city'] ?? ride['to'] ?? 'unknown';
    final start = (ride['start_time'] ?? '').toString().replaceFirst('T', ' ');
    final price = ride['price_inr'] ?? 0;
    final seatsLeft = ride['seats_left'] ?? ride['seats_available'] ?? 0;
    final type = ride['type'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : ListView(
          children: [
            Text('$from → $to', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Date: $start'),
            Text('Seats available: $seatsLeft'),
            Text('Type: $type'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _fromStopId,
              items: _stops
                  .map((s) => DropdownMenuItem(
                value: (s['stop_id'] ?? s['id']).toString(),
                child: Text(s['stop_name'] ?? s['name'] ?? 'Stop'),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _fromStopId = v),
              decoration: const InputDecoration(labelText: 'Pickup stop'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _toStopId,
              items: _stops
                  .map((s) => DropdownMenuItem(
                value: (s['stop_id'] ?? s['id']).toString(),
                child: Text(s['stop_name'] ?? s['name'] ?? 'Stop'),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _toStopId = v),
              decoration: const InputDecoration(labelText: 'Drop stop'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _seats,
              items: List.generate(6, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text(n.toString())))
                  .toList(),
              onChanged: (v) => setState(() => _seats = v ?? 1),
              decoration: const InputDecoration(labelText: 'Seats'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _book,
              child: Text('Book Seat  •  ₹${price * _seats}'),
            ),
          ],
        ),
      ),
    );
  }
}
