import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:5000');
const String devUserId   = String.fromEnvironment('DEV_USER_ID',   defaultValue: '1c990b95-cb96-467f-b6fe-33346feb7a76');

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CarShare Dev',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const Home(),
  );
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }

class _HomeState extends State<Home> {
  String log = 'Tap buttons to test';

  Future<void> pingHealth() async {
    setState(() => log = 'Pinging /health...');
    final res = await http.get(Uri.parse('$apiBaseUrl/health'));
    setState(() => log = '${res.statusCode} ${res.body}');
  }

  Future<void> whoAmI() async {
    setState(() => log = 'GET /users/me ...');
    final res = await http.get(Uri.parse('$apiBaseUrl/users/me'),
      headers: { 'x-user-id': devUserId });
    setState(() => log = '${res.statusCode} ${res.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CarShare Dev')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('API: $apiBaseUrl\nUser: $devUserId', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ElevatedButton(onPressed: pingHealth, child: const Text('Ping /health')),
            ElevatedButton(onPressed: whoAmI, child: const Text('GET /users/me')),
          ]),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: Text(log))),
        ]),
      ),
    );
  }
}
