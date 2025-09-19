// lib/screens/tab_publish.dart - FIXED UI WITH PROPER THEME (CONTINUED)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../services/api_client.dart';

enum MessageType { success, error, warning }

class TabPublish extends StatefulWidget {
  final ApiClient api;
  
  const TabPublish({super.key, required this.api});

  @override
  State<TabPublish> createState() => _TabPublishState();
}

class _TabPublishState extends State<TabPublish> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fromCityController = TextEditingController();
  final _toCityController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State variables
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _availableRoutes = [];
  List<Map<String, dynamic>> _routeStops = [];
  
  Map<String, dynamic>? _selectedRoute;
  Set<String> _selectedPickupStops = {};
  Set<String> _selectedDropStops = {};
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _rideType = 'private_pool';
  bool _autoConfirm = true;
  
  bool _loadingCities = false;
  bool _loadingRoutes = false;
  bool _loadingStops = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _seatsController.text = '4';
  }

  @override
  void dispose() {
    _fromCityController.dispose();
    _toCityController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _notesController.dispose();
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
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  void _onCityChanged() {
    if (_fromCityController.text.isNotEmpty && _toCityController.text.isNotEmpty) {
      _loadRoutes();
    } else {
      setState(() {
        _availableRoutes.clear();
        _selectedRoute = null;
        _routeStops.clear();
        _selectedPickupStops.clear();
        _selectedDropStops.clear();
      });
    }
  }

  Future<void> _loadRoutes() async {
    setState(() => _loadingRoutes = true);
    try {
      final routes = await widget.api.getRoutes(
        from: _fromCityController.text.trim(),
        to: _toCityController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _availableRoutes = routes;
          _selectedRoute = routes.isNotEmpty ? routes.first : null;
          _routeStops.clear();
          _selectedPickupStops.clear();
          _selectedDropStops.clear();
          _loadingRoutes = false;
        });
        
        if (routes.isNotEmpty) {
          _loadStops(routes.first['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRoutes = false);
      }
    }
  }

  Future<void> _loadStops(String routeId) async {
    setState(() => _loadingStops = true);
    try {
      final stops = await widget.api.getStops(routeId);
      if (mounted) {
        setState(() {
          _routeStops = stops;
          _loadingStops = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStops = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _publishRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      _showMessage('Please select date and time', MessageType.error);
      return;
    }

    setState(() => _publishing = true);
    
    try {
      final departureDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Call the publishRide API method
      final result = await widget.api.publishRide(
        fromLocation: _fromCityController.text.trim(),
        toLocation: _toCityController.text.trim(),
        departAt: departureDateTime.toIso8601String(),
        seats: int.parse(_seatsController.text),
        pricePerSeatInr: int.parse(_priceController.text),
        rideType: _rideType,
        autoApprove: _autoConfirm,
        routeId: _selectedRoute?['id'],
        selectedPickupStops: _selectedPickupStops.toList(),
        selectedDropStops: _selectedDropStops.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        _showMessage('Ride published successfully!', MessageType.success);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        _showMessage('Error: $errorMessage', MessageType.error);
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showMessage(String message, MessageType type) {
    Color bgColor;
    IconData icon;
    
    switch (type) {
      case MessageType.success:
        bgColor = AppTheme.statusSuccess;
        icon = Icons.check_circle;
        break;
      case MessageType.error:
        bgColor = AppTheme.statusError;
        icon = Icons.error;
        break;
      case MessageType.warning:
        bgColor = AppTheme.statusWarning;
        icon = Icons.warning;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spaceLG),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fromCityController.clear();
    _toCityController.clear();
    _priceController.clear();
    _seatsController.text = '4';
    _notesController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedRoute = null;
      _rideType = 'private_pool';
      _autoConfirm = true;
      _availableRoutes.clear();
      _routeStops.clear();
      _selectedPickupStops.clear();
      _selectedDropStops.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Publish Ride'),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
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
                            child: const Icon(Icons.publish, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: AppTheme.spaceLG),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Publish Your Ride', style: AppTheme.headingSmall),
                                SizedBox(height: AppTheme.spaceXS),
                                Text('Share your journey and earn', style: AppTheme.bodyMedium),
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
                            controller: _fromCityController,
                            label: 'From City',
                            hint: 'Departure city',
                            icon: Icons.trip_origin,
                            iconColor: AppTheme.accentGreen,
                          ),
                          
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          _buildCityField(
                            controller: _toCityController,
                            label: 'To City',
                            hint: 'Destination city',
                            icon: Icons.location_on,
                            iconColor: AppTheme.accentRed,
                          ),
                        ],
                      ),
                    ),

                    // Show routes if cities are selected
                    if (_availableRoutes.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildRouteSelector(),
                    ],

                    const SizedBox(height: AppTheme.spaceXL),

                    // Date & Time Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevation: 1),
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date & Time', style: AppTheme.headingSmall),
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          Row(
                            children: [
                              Expanded(child: _buildDateButton()),
                              const SizedBox(width: AppTheme.spaceLG),
                              Expanded(child: _buildTimeButton()),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXL),

                    // Ride Details Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevation: 1),
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ride Details', style: AppTheme.headingSmall),
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _seatsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Available Seats',
                                    hintText: 'Number of seats',
                                    prefixIcon: Icon(Icons.event_seat),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    final seats = int.tryParse(value);
                                    if (seats == null || seats < 1 || seats > 8) return 'Enter 1-8 seats';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceLG),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price per Seat (₹)',
                                    hintText: 'In rupees',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    final price = int.tryParse(value);
                                    if (price == null || price < 0) return 'Enter valid price';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          DropdownButtonFormField<String>(
                            value: _rideType,
                            decoration: const InputDecoration(
                              labelText: 'Ride Type',
                              prefixIcon: Icon(Icons.directions_car),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'private_pool', child: Text('🚗 Private Pool (White Plate)')),
                              DropdownMenuItem(value: 'commercial_pool', child: Text('🚕 Commercial Pool (Yellow Plate)')),
                              DropdownMenuItem(value: 'commercial_full', child: Text('🚖 Commercial Full Booking (Yellow Plate)')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _rideType = value);
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: CheckboxListTile(
                              title: const Text('Auto-confirm bookings'),
                              subtitle: Text(
                                _autoConfirm 
                                  ? 'Bookings will be automatically approved' 
                                  : 'You\'ll manually review each booking request',
                                style: TextStyle(
                                  color: _autoConfirm ? AppTheme.statusSuccess : AppTheme.statusWarning
                                ),
                              ),
                              value: _autoConfirm,
                              onChanged: (value) => setState(() => _autoConfirm = value ?? true),
                              activeColor: AppTheme.primaryBlue,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spaceLG),
                          
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Additional Notes (Optional)',
                              hintText: 'Pickup instructions, preferences, etc.',
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                            maxLength: 500,
                          ),
                        ],
                      ),
                    ),

                    // Show stops if route is selected
                    if (_selectedRoute != null && _routeStops.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildStopsSelector(),
                    ],

                    const SizedBox(height: AppTheme.space3XL),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Publish Button
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
                onPressed: _publishing ? null : _publishRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                ),
                child: _publishing
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
                          Text('Publishing...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.publish, size: 24),
                          SizedBox(width: AppTheme.spaceMD),
                          Text('Publish Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          return _cities.take(10).map((city) => city['name'] as String);
        }
        return _cities
            .where((city) => (city['name'] as String)
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()))
            .take(10)
            .map((city) => city['name'] as String);
      },
      onSelected: (String selection) {
        controller.text = selection;
        _onCityChanged();
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
            suffixIcon: _loadingCities ? const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spaceMD),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ) : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter ${label.toLowerCase()}';
            }
            return null;
          },
          onChanged: (value) {
            controller.text = value;
            _onCityChanged();
          },
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
              ? 'Select Date'
              : DateFormat('MMM dd, yyyy').format(_selectedDate!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _pickTime,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedTime != null ? AppTheme.accentOrange : AppTheme.backgroundLight,
          foregroundColor: _selectedTime != null ? Colors.white : AppTheme.accentOrange,
          side: BorderSide(color: AppTheme.accentOrange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        icon: const Icon(Icons.access_time, size: 20),
        label: Text(
          _selectedTime == null
              ? 'Select Time'
              : _selectedTime!.format(context),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Routes', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spaceLG),
          
          if (_loadingRoutes)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Column(
                children: _availableRoutes.map<Widget>((route) {
                  final isSelected = _selectedRoute?['id'] == route['id'];
                  return Container(
                    margin: const EdgeInsets.all(AppTheme.spaceXS),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: isSelected ? Border.all(color: AppTheme.primaryBlue, width: 2) : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.radiusSM),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Icon(
                          Icons.route,
                          color: isSelected ? Colors.white : AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        route['name'] ?? 'Route',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: route['distance_km'] != null
                          ? Text('${route['distance_km']} km')
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.statusSuccess)
                          : null,
                      onTap: () {
                        setState(() => _selectedRoute = route);
                        _loadStops(route['id']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStopsSelector() {
    return Container(
      decoration: AppTheme.cardDecoration(elevation: 1),
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.radiusSM),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.location_pin, color: AppTheme.accentGreen, size: 20),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              const Text('Select Pickup & Drop Stops', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          
          if (_loadingStops)
            const Center(child: CircularProgressIndicator())
          else ...[
            const Text('Pickup Stops', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.radiusSM),
            Wrap(
              spacing: AppTheme.radiusSM,
              runSpacing: AppTheme.radiusSM,
              children: _routeStops.map<Widget>((stop) {
                final isSelected = _selectedPickupStops.contains(stop['id']);
                return FilterChip(
                  label: Text(stop['name'] ?? 'Stop'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPickupStops.add(stop['id']);
                      } else {
                        _selectedPickupStops.remove(stop['id']);
                      }
                    });
                  },
                  selectedColor: AppTheme.accentGreen.withOpacity(0.2),
                  checkmarkColor: AppTheme.accentGreen,
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            const Text('Drop Stops', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.radiusSM),
            Wrap(
              spacing: AppTheme.radiusSM,
              runSpacing: AppTheme.radiusSM,
              children: _routeStops.map<Widget>((stop) {
                final isSelected = _selectedDropStops.contains(stop['id']);
                return FilterChip(
                  label: Text(stop['name'] ?? 'Stop'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDropStops.add(stop['id']);
                      } else {
                        _selectedDropStops.remove(stop['id']);
                      }
                    });
                  },
                  selectedColor: AppTheme.accentRed.withOpacity(0.2),
                  checkmarkColor: AppTheme.accentRed,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}