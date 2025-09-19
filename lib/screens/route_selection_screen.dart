// lib/screens/route_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../env.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';

class RouteSelectionScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final Function(RouteModel selectedRoute, StopModel pickupStop, StopModel dropStop) onRouteSelected;

  const RouteSelectionScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.onRouteSelected,
  });

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  List<RouteModel> _routes = [];
  List<StopModel> _pickupStops = [];
  List<StopModel> _dropStops = [];
  RouteModel? _selectedRoute;
  StopModel? _selectedPickupStop;
  StopModel? _selectedDropStop;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('${Env.apiBase}/routes/search?from=${widget.fromCity}&to=${widget.toCity}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = (data['routes'] as List)
            .map((json) => RouteModel.fromJson(json))
            .toList();

        setState(() {
          _routes = routes;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStopsForRoute(RouteModel route) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiBase}/routes/${route.id}/stops'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stops = (data['stops'] as List)
            .map((json) => StopModel.fromJson(json))
            .toList();

        // Filter stops based on from/to cities
        final pickupStops = stops.where((stop) => 
          stop.cityName.toLowerCase().contains(widget.fromCity.toLowerCase())
        ).toList();
        
        final dropStops = stops.where((stop) => 
          stop.cityName.toLowerCase().contains(widget.toCity.toLowerCase())
        ).toList();

        setState(() {
          _pickupStops = pickupStops;
          _dropStops = dropStops;
          _selectedPickupStop = null;
          _selectedDropStop = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stops: $e')),
      );
    }
  }

  void _selectRoute(RouteModel route) {
    setState(() {
      _selectedRoute = route;
    });
    _loadStopsForRoute(route);
  }

  void _confirmSelection() {
    if (_selectedRoute != null && 
        _selectedPickupStop != null && 
        _selectedDropStop != null) {
      widget.onRouteSelected(_selectedRoute!, _selectedPickupStop!, _selectedDropStop!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Route: ${widget.fromCity} → ${widget.toCity}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _canConfirm()
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirm Route Selection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRoutes,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteSelection(),
          if (_selectedRoute != null) ...[
            const SizedBox(height: 24),
            _buildStopSelection(),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Routes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_routes.isEmpty)
              const Text('No routes found for this route.')
            else
              ..._routes.map((route) => _buildRouteCard(route)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteModel route) {
    final isSelected = _selectedRoute?.id == route.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.1) : null,
      child: ListTile(
        title: Text(
          route.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${route.fromCity} → ${route.toCity}'),
            Text('Distance: ${route.distanceKm} km | Duration: ${route.durationMinutes} min'),
            if (route.description.isNotEmpty)
              Text('Info: ${route.description}'),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
            : const Icon(Icons.radio_button_unchecked),
        onTap: () => _selectRoute(route),
      ),
    );
  }

  Widget _buildStopSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Route: ${_selectedRoute!.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPickupStopSelection(),
            const SizedBox(height: 16),
            _buildDropStopSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupStopSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Pickup Stop:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_pickupStops.isEmpty)
          Text('No pickup stops available in ${widget.fromCity}')
        else
          DropdownButtonFormField<StopModel>(
            value: _selectedPickupStop,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Choose pickup location',
            ),
            items: _pickupStops.map((stop) {
              return DropdownMenuItem(
                value: stop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stop.name),
                    if (stop.landmark.isNotEmpty)
                      Text(
                        stop.landmark,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (stop) {
              setState(() {
                _selectedPickupStop = stop;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDropStopSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Drop Stop:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_dropStops.isEmpty)
          Text('No drop stops available in ${widget.toCity}')
        else
          DropdownButtonFormField<StopModel>(
            value: _selectedDropStop,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Choose drop location',
            ),
            items: _dropStops.map((stop) {
              return DropdownMenuItem(
                value: stop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stop.name),
                    if (stop.landmark.isNotEmpty)
                      Text(
                        stop.landmark,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (stop) {
              setState(() {
                _selectedDropStop = stop;
              });
            },
          ),
      ],
    );
  }

  bool _canConfirm() {
    return _selectedRoute != null && 
           _selectedPickupStop != null && 
           _selectedDropStop != null;
  }
}
