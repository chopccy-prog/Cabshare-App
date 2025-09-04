import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublishRideScreen extends StatefulWidget {
  @override
  _PublishRideScreenState createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  final supabase = Supabase.instance.client;
  final String testUserId = '00000000-0000-0000-0000-000000000000'; // Replace with your test UUID

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int seats = 1;
  double price = 608.0;
  String selectedType = 'Private Pool';
  String errorMessage = '';

  Future<void> _publishRide() async {
    try {
      final response = await supabase.from('rides').insert([
        {
          'from_city': fromController.text,
          'to_city': toController.text,
          'date': selectedDate.toIso8601String(),
          'time': selectedTime.format(context),
          'seats': seats,
          'price': price,
          'ride_type': selectedType,
          'driver_id': testUserId, // Use UUID
        }
      ]);

      if (response.error != null) {
        setState(() => errorMessage = response.error!.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride published!')));
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
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
            TextField(controller: fromController, decoration: InputDecoration(labelText: 'From City')),
            TextField(controller: toController, decoration: InputDecoration(labelText: 'To City')),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) setState(() => selectedDate = date);
              },
              child: Row(
                children: [
                  Text('Date (YYYY-MM-DD): ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  Icon(Icons.calendar_today),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: selectedTime);
                if (time != null) setState(() => selectedTime = time);
              },
              child: Row(
                children: [
                  Text('Time (HH:mm): ${selectedTime.format(context)}'),
                  Icon(Icons.access_time),
                ],
              ),
            ),
            Row(
              children: [
                Text('Seats: $seats'),
                Slider(value: seats.toDouble(), min: 1, max: 7, onChanged: (val) => setState(() => seats = val.toInt())),
              ],
            ),
            TextField(onChanged: (val) => price = double.tryParse(val) ?? 0, decoration: InputDecoration(labelText: 'Price (₹/seat)')),
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
            if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _publishRide, child: Text('Publish')),
          ],
        ),
      ),
    );
  }
}