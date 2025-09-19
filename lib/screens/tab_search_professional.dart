// lib/screens/tab_search_professional.dart - ALIGNED WITH NEW APP THEME
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../core/theme/app_theme.dart';
import 'ride_detail_booking.dart';

class TabSearchProfessional extends StatefulWidget {
  final ApiClient api;
  
  const TabSearchProfessional({super.key, required this.api});

  @override
  State<TabSearchProfessional> createState() => _TabSearchProfessionalState();
}

class _TabSearchProfessionalState extends State<TabSearchProfessional> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  
  // State variables
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _searchResults = [];
  
  DateTime? _selectedDate;
  String _selectedRideType = 'all';
  
  bool _loadingCities = false;
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() => _loadingCities = true);
    try {
      final cities = await widget.api.getCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
        });
      }
    } catch (e) {
      print('Error loading cities: $e');
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _searchRides() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _searching = true;
      _hasSearched = false;
    });

    try {
      final searchResults = await widget.api.searchRides(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        when: _selectedDate != null 
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
            : null,
        type: _selectedRideType != 'all' ? _selectedRideType : null,
      );
      
      setState(() {
        _hasSearched = true;
        _searchResults = searchResults;
      });
    } catch (e) {
      setState(() {
        _hasSearched = true;
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailBooking(ride: ride, api: widget.api),
      ),
    );
    
    if (result == true) {
      _searchRides(); // Refresh results
    }
  }

  void _clearSearch() {
    setState(() {
      _fromController.clear();
      _toController.clear();
      _selectedDate = null;
      _selectedRideType = 'all';
      _searchResults.clear();
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Search Rides'),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
        actions: [
          if (_hasSearched)
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      decoration: AppTheme.cardDecoration(elevation: 1),
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMD),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: const Icon(Icons.search, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: AppTheme.spaceLG),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Find Your Ride', style: AppTheme.headingSmall),
                                SizedBox(height: AppTheme.spaceXS),
                                Text('Search available rides', style: AppTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXL),

                    // Location Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevation: 1),
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Journey Details', style: AppTheme.headingSmall),
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          _buildCityField(
                            controller: _fromController,
                            label: 'From City',
                            hint: 'Departure city',
                            icon: Icons.trip_origin,
                            iconColor: AppTheme.accentGreen,
                          ),
                          
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          _buildCityField(
                            controller: _toController,
                            label: 'To City',
                            hint: 'Destination city',
                            icon: Icons.location_on,
                            iconColor: AppTheme.accentRed,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXL),

                    // Date & Filters Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevation: 1),
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date & Filters', style: AppTheme.headingSmall),
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          Row(
                            children: [
                              Expanded(child: _buildDateButton()),
                              const SizedBox(width: AppTheme.spaceLG),
                              Expanded(child: _buildRideTypeDropdown()),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.space3XL),

                    // Search Results Section
                    if (_hasSearched) ...[
                      if (_searchResults.isNotEmpty) ...[
                        Container(
                          decoration: AppTheme.cardDecoration(elevation: 1),
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spaceMD),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: const Icon(Icons.list_alt, color: AppTheme.accentGreen, size: 24),
                              ),
                              const SizedBox(width: AppTheme.spaceLG),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Rides (${_searchResults.length})',
                                      style: AppTheme.headingSmall,
                                    ),
                                    if (_selectedDate != null)
                                      Text(
                                        'For ${DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!)}',
                                        style: AppTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spaceXL),
                        
                        ..._searchResults.map((ride) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
                          child: _buildRideCard(ride),
                        )),
                      ] else
                        _buildEmptyState(),
                    ] else
                      _buildInitialState(),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Search Button
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _searching ? null : _searchRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                ),
                child: _searching
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
                          SizedBox(width: AppTheme.spaceMD),
                          Text('Searching...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 24),
                          SizedBox(width: AppTheme.spaceMD),
                          Text('Search Rides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _cities.take(8).map((city) => city['name'] as String);
        }
        return _cities
            .where((city) => (city['name'] as String)
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()))
            .take(8)
            .map((city) => city['name'] as String);
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.text = controller.text;
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            suffixIcon: _loadingCities 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceMD),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ) 
                : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter ${label.toLowerCase()}';
            }
            return null;
          },
          onChanged: (value) => controller.text = value,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildDateButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _pickDate,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedDate != null ? AppTheme.primaryBlue : AppTheme.backgroundLight,
          foregroundColor: _selectedDate != null ? Colors.white : AppTheme.primaryBlue,
          side: BorderSide(color: AppTheme.primaryBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        icon: const Icon(Icons.calendar_today, size: 20),
        label: Text(
          _selectedDate == null
              ? 'Any Date'
              : DateFormat('MMM dd').format(_selectedDate!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildRideTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRideType,
      decoration: const InputDecoration(
        labelText: 'Ride Type',
        prefixIcon: Icon(Icons.directions_car),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Types')),
        DropdownMenuItem(value: 'private_pool', child: Text('Private Pool')),
        DropdownMenuItem(value: 'commercial_pool', child: Text('Commercial Pool')),
        DropdownMenuItem(value: 'commercial_full', child: Text('Commercial Full')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRideType = value);
        }
      },
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final seatsAvailable = ride['seats_available'] ?? 0;
    final isAvailable = seatsAvailable > 0;
    final from = ride['from'] ?? ride['from_location'] ?? 'Unknown';
    final to = ride['to'] ?? ride['to_location'] ?? 'Unknown';
    final pricePerSeat = ride['price_per_seat_inr'] ?? ride['price'] ?? 0;
    
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 2),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$from → $to', style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryBlue)),
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(_formatRideTime(ride), style: AppTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(color: AppTheme.statusSuccess.withOpacity(0.3)),
                  ),
                  child: Text(
                    '₹$pricePerSeat',
                    style: const TextStyle(
                      color: AppTheme.statusSuccess,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // Details
            Row(
              children: [
                _buildDetailChip(
                  Icons.airline_seat_recline_normal,
                  '$seatsAvailable seats',
                  isAvailable ? AppTheme.accentOrange : AppTheme.textMuted,
                ),
                const SizedBox(width: AppTheme.spaceMD),
                _buildDetailChip(
                  Icons.directions_car,
                  _getRideTypeLabel(ride['ride_type'] ?? 'private_pool'),
                  AppTheme.primaryBlue,
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isAvailable ? () => _bookRide(ride) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? AppTheme.statusSuccess : AppTheme.textMuted,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                icon: Icon(isAvailable ? Icons.bookmark_add : Icons.block),
                label: Text(isAvailable ? 'Book Ride' : 'Fully Booked'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getRideTypeLabel(String rideType) {
    switch (rideType) {
      case 'private_pool': return 'Private Pool';
      case 'commercial_pool': return 'Commercial Pool';
      case 'commercial_full': return 'Commercial Full';
      default: return 'Private Pool';
    }
  }

  String _formatRideTime(Map<String, dynamic> ride) {
    try {
      if (ride['depart_date'] != null && ride['depart_time'] != null) {
        final dateStr = ride['depart_date'] as String;
        final timeStr = ride['depart_time'] as String;
        final dateTime = DateTime.parse('${dateStr}T$timeStr');
        return DateFormat('MMM dd, HH:mm').format(dateTime);
      } else if (ride['when'] != null) {
        final dateTime = DateTime.parse(ride['when'] as String);
        return DateFormat('MMM dd, HH:mm').format(dateTime);
      }
    } catch (e) {
      // Fallback for any parsing errors
    }
    return 'Time not specified';
  }

  Widget _buildInitialState() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.space3XL),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car,
              size: 60,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          const Text('Find Your Perfect Ride', style: AppTheme.headingMedium),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'Search for rides between cities and book your journey',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.space3XL),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 40,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          const Text('No rides found', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spaceMD),
          const Text(
            'Try adjusting your search criteria or check back later',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXL),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedRideType = 'all';
              });
              _searchRides();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Search Again'),
          ),
        ],
      ),
    );
  }
}