// lib/screens/ride_detail_booking.dart - Ride Details with Pickup/Drop Selection
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class RideDetailBooking extends StatefulWidget {
  final Map<String, dynamic> ride;
  final ApiClient api;
  
  const RideDetailBooking({super.key, required this.ride, required this.api});

  @override
  State<RideDetailBooking> createState() => _RideDetailBookingState();
}

class _RideDetailBookingState extends State<RideDetailBooking> {
  List<Map<String, dynamic>> _availableStops = [];
  String? _selectedPickupStop;
  String? _selectedDropStop;
  int _selectedSeats = 1;
  bool _loadingStops = false;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() => _loadingStops = true);
    try {
      final routeId = widget.ride['route_id'];
      if (routeId != null) {
        final stops = await widget.api.getStops(routeId.toString());
        if (mounted) {
          setState(() {
            _availableStops = stops;
            _loadingStops = false;
          });
        }
      } else {
        // Create default stops if no route
        setState(() {
          _availableStops = [
            {'id': 'start', 'name': 'Starting Point', 'is_pickup': true, 'is_drop': false},
            {'id': 'end', 'name': 'Destination', 'is_pickup': false, 'is_drop': true},
          ];
          _loadingStops = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStops = false);
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedPickupStop == null || _selectedDropStop == null) {
      _showMessage('Please select pickup and drop stops', false);
      return;
    }

    setState(() => _booking = true);
    
    try {
      await widget.api.createBooking(
        rideId: widget.ride['id'].toString(),
        seats: _selectedSeats,
        pickupStopId: _selectedPickupStop,
        dropStopId: _selectedDropStop,
      );

      if (mounted) {
        _showMessage('Booking confirmed successfully!', true);
        Navigator.pop(context, true); // Return true to indicate successful booking
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Booking failed: ${e.toString().replaceAll('Exception: ', '')}', false);
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.ride['from'] ?? widget.ride['from_location'] ?? 'Unknown';
    final to = widget.ride['to'] ?? widget.ride['to_location'] ?? 'Unknown';
    final seatsAvailable = widget.ride['seats_available'] ?? 0;
    final pricePerSeat = widget.ride['price_per_seat_inr'] ?? widget.ride['price'] ?? 0;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Book Ride'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ride Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$from → $to',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(_formatRideTime()),
                            const SizedBox(width: 20),
                            const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('$pricePerSeat per seat', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('$seatsAvailable seats available'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seats Selection
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Number of Seats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _selectedSeats > 1 ? () => setState(() => _selectedSeats--) : null,
                              icon: const Icon(Icons.remove),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_selectedSeats',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: _selectedSeats < seatsAvailable ? () => setState(() => _selectedSeats++) : null,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ₹${pricePerSeat * _selectedSeats}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pickup & Drop Selection
                  if (_loadingStops)
                    const Center(child: CircularProgressIndicator())
                  else if (_availableStops.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Pickup & Drop Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          
                          // Pickup Selection
                          const Text('Pickup Point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableStops.where((stop) => stop['is_pickup'] == true).map<Widget>((stop) {
                              final isSelected = _selectedPickupStop == stop['id'];
                              return ChoiceChip(
                                label: Text(stop['name'] ?? 'Stop'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedPickupStop = stop['id']);
                                  }
                                },
                                selectedColor: Colors.green.withOpacity(0.2),
                                checkmarkColor: Colors.green,
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Drop Selection
                          const Text('Drop Point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableStops.where((stop) => stop['is_drop'] == true).map<Widget>((stop) {
                              final isSelected = _selectedDropStop == stop['id'];
                              return ChoiceChip(
                                label: Text(stop['name'] ?? 'Stop'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedDropStop = stop['id']);
                                  }
                                },
                                selectedColor: Colors.red.withOpacity(0.2),
                                checkmarkColor: Colors.red,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Book Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _booking ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _booking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Booking...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_add, size: 24),
                          const SizedBox(width: 12),
                          Text('Confirm Booking (₹${pricePerSeat * _selectedSeats})', 
                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRideTime() {
    try {
      if (widget.ride['depart_date'] != null && widget.ride['depart_time'] != null) {
        final dateStr = widget.ride['depart_date'] as String;
        final timeStr = widget.ride['depart_time'] as String;
        final dateTime = DateTime.parse('${dateStr}T$timeStr');
        return DateFormat('MMM dd, yyyy at HH:mm').format(dateTime);
      } else if (widget.ride['when'] != null) {
        final dateTime = DateTime.parse(widget.ride['when'] as String);
        return DateFormat('MMM dd, yyyy at HH:mm').format(dateTime);
      }
    } catch (e) {
      // Fallback for any parsing errors
    }
    return 'Time not specified';
  }
}