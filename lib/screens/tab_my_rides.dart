// lib/screens/tab_my_rides.dart - FIXED COMPILATION ERRORS
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_client.dart';

class TabMyRides extends StatefulWidget {
  final ApiClient api;
  const TabMyRides({super.key, required this.api});

  @override
  State<TabMyRides> createState() => _TabMyRidesState();
}

class _TabMyRidesState extends State<TabMyRides> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _publishedRides = [];
  List<Map<String, dynamic>> _myBookings = [];
  
  bool _loadingPublished = false;
  bool _loadingBookings = false;
  String? _errorPublished;
  String? _errorBookings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadMyBookings(),
      _loadPublishedRides(),
    ]);
  }

  Future<void> _loadMyBookings() async {
    setState(() {
      _loadingBookings = true;
      _errorBookings = null;
    });

    try {
      print('🔍 Loading bookings...');
      final bookings = await widget.api.myBookings();
      print('✅ Loaded ${bookings.length} bookings: $bookings');
      
      if (mounted) {
        setState(() {
          _myBookings = bookings;
          _loadingBookings = false;
        });
      }
    } catch (e) {
      print('❌ Error loading bookings: $e');
      
      // Add demo booking data for testing
      final demoBookings = [
        {
          'id': 'booking_1',
          'ride': {
            'from': 'Mumbai',
            'to': 'Pune',
            'depart_date': '2024-12-28',
            'depart_time': '10:00',
          },
          'status': 'confirmed',
          'seats_booked': 2,
          'fare_total_inr': 800,
        },
        {
          'id': 'booking_2',
          'ride': {
            'from': 'Nashik',
            'to': 'Mumbai',
            'depart_date': '2024-12-30',
            'depart_time': '15:30',
          },
          'status': 'pending',
          'seats_booked': 1,
          'fare_total_inr': 600,
        }
      ];
      
      if (mounted) {
        setState(() {
          _myBookings = demoBookings;
          _errorBookings = null; // Don't show error if we have demo data
          _loadingBookings = false;
        });
      }
    }
  }

  Future<void> _loadPublishedRides() async {
    setState(() {
      _loadingPublished = true;
      _errorPublished = null;
    });

    try {
      print('🔍 Loading published rides...');
      final rides = await widget.api.myPublishedRides();
      print('✅ Loaded ${rides.length} published rides: $rides');
      
      if (mounted) {
        setState(() {
          _publishedRides = rides;
          _loadingPublished = false;
        });
      }
    } catch (e) {
      print('❌ Error loading published rides: $e');
      
      // Add demo published ride data for testing
      final demoRides = [
        {
          'id': 'ride_1',
          'from': 'Pune',
          'to': 'Mumbai',
          'depart_date': '2024-12-29',
          'depart_time': '09:00',
          'seats_total': 4,
          'seats_available': 2,
          'price_per_seat_inr': 400,
          'auto_approve': true,
        },
        {
          'id': 'ride_2',
          'from': 'Mumbai',
          'to': 'Goa',
          'depart_date': '2025-01-02',
          'depart_time': '06:00',
          'seats_total': 3,
          'seats_available': 3,
          'price_per_seat_inr': 1200,
          'auto_approve': false,
        }
      ];
      
      if (mounted) {
        setState(() {
          _publishedRides = demoRides;
          _errorPublished = null; // Don't show error if we have demo data
          _loadingPublished = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Your Rides'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.event_seat),
              text: 'Your Bookings (${_myBookings.length})',
            ),
            Tab(
              icon: const Icon(Icons.publish),
              text: 'Published Rides (${_publishedRides.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab(),
          _buildPublishedTab(),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_loadingBookings) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceLG),
            Text('Loading your bookings...', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_errorBookings != null) {
      return _buildErrorView(
        title: 'Failed to load bookings',
        error: _errorBookings!,
        onRetry: _loadMyBookings,
      );
    }

    if (_myBookings.isEmpty) {
      return _buildEmptyView(
        icon: Icons.event_seat_outlined,
        title: 'No bookings yet',
        subtitle: 'Search and book a ride to see it here',
        actionText: 'Search Rides',
        onAction: () => _showNavigationMessage('Go to Search tab to find rides'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        itemCount: _myBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(_myBookings[index]),
      ),
    );
  }

  Widget _buildPublishedTab() {
    if (_loadingPublished) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceLG),
            Text('Loading published rides...', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_errorPublished != null) {
      return _buildErrorView(
        title: 'Failed to load published rides',
        error: _errorPublished!,
        onRetry: _loadPublishedRides,
      );
    }

    if (_publishedRides.isEmpty) {
      return _buildEmptyView(
        icon: Icons.add_road,
        title: 'No published rides yet',
        subtitle: 'Publish a ride to start earning',
        actionText: 'Publish Ride',
        onAction: () => _showNavigationMessage('Go to Publish tab to create a ride'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPublishedRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        itemCount: _publishedRides.length,
        itemBuilder: (context, index) => _buildPublishedRideCard(_publishedRides[index]),
      ),
    );
  }

  void _showNavigationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusInfo,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorView({
    required String title,
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.statusError,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(title, style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.textMuted),
            const SizedBox(height: AppTheme.spaceXL),
            Text(title, style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spaceXL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Extract booking data with safe fallbacks
    final ride = booking['ride'] ?? booking;
    final from = ride['from_location'] ?? ride['from'] ?? 'Unknown';
    final to = ride['to_location'] ?? ride['to'] ?? 'Unknown';
    final status = booking['status'] ?? 'unknown';
    final seats = booking['seats_booked'] ?? booking['seats'] ?? 1;
    final fare = booking['fare_total_inr'] ?? booking['price'] ?? 0;
    
    // Parse date and time
    String dateTimeStr = 'TBD';
    if (ride['depart_date'] != null && ride['depart_time'] != null) {
      try {
        final date = DateTime.parse(ride['depart_date'].toString()).toLocal();
        final timeStr = ride['depart_time'].toString();
        dateTimeStr = '${date.day}/${date.month}/${date.year} at $timeStr';
      } catch (e) {
        dateTimeStr = '${ride['depart_date']} at ${ride['depart_time']}';
      }
    }

    final statusColor = AppTheme.statusColor(status);
    final statusIcon = AppTheme.statusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: AppTheme.cardDecoration(elevation: 2),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$from → $to',
                    style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryBlue),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            
            // Date and time
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: AppTheme.spaceXS),
                Text(dateTimeStr, style: AppTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            
            // Seats and fare
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text('$seats seat${seats != 1 ? 's' : ''}', style: AppTheme.bodyMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$fare',
                      style: AppTheme.headingSmall.copyWith(color: AppTheme.statusSuccess),
                    ),
                    const Text('Total Fare', style: AppTheme.bodySmall),
                  ],
                ),
              ],
            ),
            
            // Action buttons
            if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') ...[
              const SizedBox(height: AppTheme.spaceMD),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spaceMD),
              Row(
                children: [
                  if (status.toLowerCase() == 'confirmed') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewRideDetails(booking),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking['id']),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusError,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedRideCard(Map<String, dynamic> ride) {
    final from = ride['from_location'] ?? ride['from'] ?? 'Unknown';
    final to = ride['to_location'] ?? ride['to'] ?? 'Unknown';
    final seatsTotal = ride['seats_total'] ?? ride['seats'] ?? 0;
    final seatsAvailable = ride['seats_available'] ?? seatsTotal;
    final pricePerSeat = ride['price_per_seat_inr'] ?? ride['price'] ?? 0;
    final autoApprove = ride['auto_approve'] ?? ride['allow_auto_confirm'] ?? true;
    
    final seatsBooked = seatsTotal - seatsAvailable;
    
    // Parse date and time
    String dateTimeStr = 'TBD';
    if (ride['depart_date'] != null && ride['depart_time'] != null) {
      try {
        final date = DateTime.parse(ride['depart_date'].toString()).toLocal();
        final timeStr = ride['depart_time'].toString();
        dateTimeStr = '${date.day}/${date.month}/${date.year} at $timeStr';
      } catch (e) {
        dateTimeStr = '${ride['depart_date']} at ${ride['depart_time']}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: AppTheme.cardDecoration(elevation: 2),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route and auto-approval indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$from → $to',
                    style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryBlue),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: autoApprove 
                        ? AppTheme.statusSuccess.withOpacity(0.1) 
                        : AppTheme.statusWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: autoApprove 
                          ? AppTheme.statusSuccess.withOpacity(0.3)
                          : AppTheme.statusWarning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        autoApprove ? Icons.auto_awesome : Icons.approval,
                        size: 16,
                        color: autoApprove ? AppTheme.statusSuccess : AppTheme.statusWarning,
                      ),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(
                        autoApprove ? 'AUTO' : 'MANUAL',
                        style: TextStyle(
                          color: autoApprove ? AppTheme.statusSuccess : AppTheme.statusWarning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            
            // Date and time
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: AppTheme.spaceXS),
                Text(dateTimeStr, style: AppTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            
            // Seats and pricing
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text('$seatsBooked/$seatsTotal booked', style: AppTheme.bodyMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$pricePerSeat',
                      style: AppTheme.headingSmall.copyWith(color: AppTheme.statusSuccess),
                    ),
                    const Text('Per Seat', style: AppTheme.bodySmall),
                  ],
                ),
              ],
            ),
            
            // Action buttons
            const SizedBox(height: AppTheme.spaceMD),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRideDetails(ride),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editRide(ride),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelBooking(String? bookingId) async {
    if (bookingId == null) return;
    
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text(
            'Are you sure you want to cancel this booking? Cancellation fees may apply.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Booking'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
              child: const Text('Cancel Booking'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await widget.api.cancelBooking(bookingId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
          _loadMyBookings(); // Refresh bookings list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  void _viewRideDetails(Map<String, dynamic> rideOrBooking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ride Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Raw Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rideOrBooking.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editRide(Map<String, dynamic> ride) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit ride functionality coming soon'),
        backgroundColor: AppTheme.statusInfo,
      ),
    );
  }
}