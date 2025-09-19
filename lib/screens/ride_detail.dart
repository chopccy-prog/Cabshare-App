// lib/screens/ride_detail.dart - SIMPLE WORKING VERSION
// Basic ride detail with booking functionality
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class RideDetail extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic> ride;

  const RideDetail({
    super.key,
    required this.api,
    required this.ride,
  });

  @override
  State<RideDetail> createState() => _RideDetailState();
}

class _RideDetailState extends State<RideDetail> {
  bool _booking = false;
  int _selectedSeats = 1;

  Future<void> _bookRide() async {
    setState(() {
      _booking = true;
    });

    try {
      print('Booking ride: ${widget.ride['id']}');
      print('Seats: $_selectedSeats');

      final result = await widget.api.createBooking(
        rideId: widget.ride['id'].toString(),
        seats: _selectedSeats,
        pickupStopId: 'stop_1', // Default pickup
        dropStopId: 'stop_5',   // Default drop
      );

      print('Booking result: $result');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Booking successful! Check My Rides for details.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Go back to search
      }
    } catch (e) {
      print('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _booking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final from = ride['from'] ?? 'Unknown';
    final to = ride['to'] ?? 'Unknown';
    final when = ride['when'] ?? '';
    final price = ride['price'] ?? ride['price_per_seat_inr'] ?? 0;
    final seatsAvailable = ride['seats_available'] ?? ride['seats'] ?? 0;
    final rideType = ride['pool'] ?? ride['ride_type'] ?? 'private_pool';
    final notes = ride['notes'] ?? '';
    final driverName = ride['driverName'] ?? ride['driver_name'] ?? 'Driver';

    // Parse date/time
    String displayDateTime = 'Date not set';
    
    try {
      if (when.isNotEmpty) {
        final parts = when.split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          
          final date = DateTime.tryParse(datePart);
          if (date != null) {
            final dateStr = DateFormat('EEEE, MMM dd, yyyy').format(date);
            final timeStr = timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
            displayDateTime = '$dateStr at $timeStr';
          }
        }
      }
    } catch (e) {
      displayDateTime = when.isNotEmpty ? when : 'Date not set';
    }

    final totalPrice = price * _selectedSeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
                          // From to To
                          Row(
                            children: [
                              // From
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.trip_origin, size: 16, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text('From', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      from,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Arrow
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.arrow_forward, color: Colors.blue),
                              ),
                              
                              // To
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('To', style: TextStyle(color: Colors.grey)),
                                        SizedBox(width: 4),
                                        Icon(Icons.location_on, size: 16, color: Colors.red),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      to,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Trip Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
                          // Date and Time
                          Row(
                            children: [
                              const Icon(Icons.schedule, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Departure',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayDateTime,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Available Seats and Price
                          Row(
                            children: [
                              // Seats
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.airline_seat_recline_normal, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Available Seats',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$seatsAvailable seats',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Price
                              Row(
                                children: [
                                  const Icon(Icons.currency_rupee, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Price per Seat',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹$price',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Ride Type
                          Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.purple),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ride Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRideTypeColor(rideType).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _getRideTypeColor(rideType)),
                                    ),
                                    child: Text(
                                      _getRideTypeLabel(rideType),
                                      style: TextStyle(
                                        color: _getRideTypeColor(rideType),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Notes (if any)
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Additional Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        notes,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Driver Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: Text(
                                  driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driverName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Available after booking',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Booking Options Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Options',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
                          // Seats Selection
                          Row(
                            children: [
                              const Text(
                                'Number of Seats:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _selectedSeats > 1 ? () {
                                      setState(() {
                                        _selectedSeats--;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_selectedSeats',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _selectedSeats < seatsAvailable ? () {
                                      setState(() {
                                        _selectedSeats++;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Total Price
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calculate, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Amount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '₹$price × $_selectedSeats seat${_selectedSeats == 1 ? '' : 's'} = ₹$totalPrice',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹$totalPrice',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for fixed button
                ],
              ),
            ),
          ),
          
          // Fixed Book Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_booking || seatsAvailable == 0) ? null : _bookRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    : seatsAvailable == 0
                        ? const Text(
                            'Ride Full',
                            style: TextStyle(fontSize: 18),
                          )
                        : Text(
                            'Book Ride - ₹$totalPrice',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRideTypeColor(String type) {
    switch (type) {
      case 'private_pool':
        return Colors.blue;
      case 'commercial_pool':
        return Colors.orange;
      case 'commercial_full':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRideTypeLabel(String type) {
    switch (type) {
      case 'private_pool':
        return 'Private Pool (White Plate)';
      case 'commercial_pool':
        return 'Commercial Pool (Yellow Plate)';
      case 'commercial_full':
        return 'Commercial Full Booking';
      default:
        return 'Unknown Type';
    }
  }
}
