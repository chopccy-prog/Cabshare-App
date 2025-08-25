import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ====== CONFIG (edit these) ======
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000', // change to your PC's IP if needed
);
const String devUserId = String.fromEnvironment(
  'DEV_USER_ID',
  defaultValue: '<PASTE_A_USERS_APP_UUID_HERE>',
);
// ==================================

void main() {
  runApp(const CarShareApp());
}

class CarShareApp extends StatelessWidget {
  const CarShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarShare Dev',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HealthScreen(),
    );
  }
}

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String _status = 'Tap the button to ping backend';

  Future<void> _ping() async {
    setState(() => _status = 'Pinging...');
    try {
      final uri = Uri.parse('$apiBaseUrl/health');
      final res = await http.get(uri, headers: {
        // dev header your backend accepts (kept for future)
        'x-user-id': devUserId,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _status = '✅ ${data['ok']} @ ${data['time']}');
      } else {
        setState(() => _status = '❌ ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      setState(() => _status = '❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CarShare (Web Dev)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend: $apiBaseUrl', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('x-user-id: $devUserId', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _ping,
              child: const Text('Ping /health'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
