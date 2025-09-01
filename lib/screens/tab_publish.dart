// lib/screens/tab_publish.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabPublish extends StatefulWidget {
  final ApiClient api;
  const TabPublish({super.key, required this.api});

  @override
  State<TabPublish> createState() => _TabPublishState();
}

class _TabPublishState extends State<TabPublish> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _whenDate = TextEditingController();
  final _whenTime = TextEditingController();
  final _seats = TextEditingController(text: '3');
  final _price = TextEditingController(text: '200');

  bool _busy = false;
  String? _msg;

  Future<void> _publish() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final ride = await widget.api.publishRide({
        'from': _from.text.trim(),
        'to': _to.text.trim(),
        'whenDate': _whenDate.text.trim(),
        'whenTime': _whenTime.text.trim(),
        'seats': int.parse(_seats.text),
        'price': int.parse(_price.text),
        'pool': 'private'
      });
      setState(() { _msg = 'Published ride ${ride?['id'] ?? ''}'; });
    } catch (e) {
      setState(() { _msg = 'Error: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _from, decoration: const InputDecoration(labelText: 'From City'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _to, decoration: const InputDecoration(labelText: 'To City'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _whenDate, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _whenTime, decoration: const InputDecoration(labelText: 'Time (HH:mm)'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _seats, decoration: const InputDecoration(labelText: 'Seats'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _publish, child: const Text('Publish')),
          if (_msg != null) Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_msg!),
          )
        ],
      ),
    );
  }
}
