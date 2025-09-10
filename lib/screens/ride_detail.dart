// lib/screens/ride_detail.dart
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
  bool _loading = false;

  String get _rideId =>
      (widget.ride['id'] ?? widget.ride['ride_id'] ?? '').toString();

  Future<void> _loadStops() async {
    // If your ride has a route_id, pull its stops; else show a simple From/To pair.
    final routeId = widget.ride['route_id'];
    if (routeId != null && routeId.toString().isNotEmpty) {
      try {
        final list = await widget.api.getRouteStops(routeId.toString());
        setState(() {
          _stops = list.cast<Map<String, dynamic>>();
        });
      } catch (e) {
        debugPrint('getRouteStops failed: $e');
        // fall back to simple two stops below
      }
    }

    if (_stops.isEmpty) {
      // Minimal fallback to keep booking unblocked
      final fromName =
          widget.ride['from_location'] ?? widget.ride['from_city'] ?? 'Origin';
      final toName =
          widget.ride['to_location'] ?? widget.ride['to_city'] ?? 'Destination';

      _stops = [
        {'id': 'from', 'name': fromName},
        {'id': 'to', 'name': toName},
      ];
    }

    // sensible defaults
    _fromStopId = _stops.first['id'].toString();
    _toStopId = _stops.last['id'].toString();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _book() async {
    if (_rideId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid ride id')));
      return;
    }

    setState(() => _loading = true);
    try {
      Map<String, dynamic> result;

      // Prefer createBooking if we have stop ids; otherwise fallback to requestBooking.
      if (_fromStopId != null && _toStopId != null) {
        result = await widget.api.createBooking(
          rideId: _rideId,
          fromStopId: _fromStopId!,
          toStopId: _toStopId!,
          seats: _seats,
          // optional money/flags can be left null to let backend compute
        );
      } else {
        // Old backend compatibility (no stop ids)
        result = await widget.api.requestBooking(_rideId, _seats);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request submitted')),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      debugPrint('Booking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.ride['from_location'] ?? widget.ride['from_city'] ?? '-';
    final to = widget.ride['to_location'] ?? widget.ride['to_city'] ?? '-';
    final date = widget.ride['depart_at'] ?? widget.ride['departure_at'] ?? '';
    final price = widget.ride['price_per_seat_inr'] ?? widget.ride['fare_per_seat_inr'] ?? '-';
    final type = widget.ride['ride_type'] ?? widget.ride['type'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('$from → $to'),
                subtitle: Text('Date: $date  |  ₹$price  |  $type'),
              ),
            ),
            const SizedBox(height: 12),

            // Stop selectors
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromStopId,
                    items: _stops
                        .map((s) => DropdownMenuItem<String>(
                      value: s['id'].toString(),
                      child: Text(s['name']?.toString() ?? s['id'].toString()),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _fromStopId = v),
                    decoration: const InputDecoration(
                      labelText: 'Pickup stop',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toStopId,
                    items: _stops
                        .map((s) => DropdownMenuItem<String>(
                      value: s['id'].toString(),
                      child: Text(s['name']?.toString() ?? s['id'].toString()),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _toStopId = v),
                    decoration: const InputDecoration(
                      labelText: 'Drop stop',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Seats selector
            Row(
              children: [
                const Text('Seats:'),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_seats', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _seats++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _book,
                icon: _loading
                    ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Request booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
