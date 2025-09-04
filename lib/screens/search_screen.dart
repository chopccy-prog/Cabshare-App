import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;

  TextEditingController fromController = TextEditingController(text: 'Nashik');
  TextEditingController toController = TextEditingController(text: 'Pune');
  DateTime selectedDate = DateTime.now();
  List<dynamic> rides = [];
  bool isLoading = false;
  String errorMessage = '';
  String selectedType = 'Private Pool'; // Default

  Future<void> _searchRides() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await supabase
          .from('rides')
          .select('*')
          .eq('from_city', fromController.text) // Fixed: 'from_city' instead of 'from_location'
          .eq('to_city', toController.text)
          .gte('date', selectedDate.toIso8601String()) // Adjust for date filter
          .eq('ride_type', selectedType); // Filter by type

      setState(() {
        rides = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cabshare')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: fromController, decoration: InputDecoration(labelText: 'From (e.g., Nashik)')),
            TextField(controller: toController, decoration: InputDecoration(labelText: 'To (e.g., Pune)')),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) setState(() => selectedDate = date);
              },
              child: Row(
                children: [
                  Text('Date (tap to pick): ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  Icon(Icons.calendar_today),
                ],
              ),
            ),
            ToggleButtons(
              children: [Text('Private Pool'), Text('Commercial Pool'), Text('Commercial Full Car')],
              isSelected: [selectedType == 'Private Pool', selectedType == 'Commercial Pool', selectedType == 'Commercial Full Car'],
              onPressed: (index) {
                setState(() {
                  if (index == 0) selectedType = 'Private Pool';
                  if (index == 1) selectedType = 'Commercial Pool';
                  if (index == 2) selectedType = 'Commercial Full Car';
                });
              },
            ),
            ElevatedButton(onPressed: _searchRides, child: Text('Search')),
            if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
            if (isLoading) CircularProgressIndicator(),
            if (!isLoading && rides.isEmpty) Text('No rides found for this category.'),
            // Add ListView.builder to display rides
          ],
        ),
      ),
    );
  }
}