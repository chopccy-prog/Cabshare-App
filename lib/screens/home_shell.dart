// lib/screens/home_shell.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_client.dart';
import 'tab_search.dart';
import 'tab_publish.dart';
import 'tab_my_rides.dart';
import 'tab_inbox.dart';
import 'tab_profile.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;
  static const String backendUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'http://192.168.1.3:3000');
  final ApiClient _api = ApiClient(baseUrl: backendUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cabshare')),
      body: IndexedStack(
        index: _idx,
        children: [
          TabSearch(api: _api),
          TabPublish(api: _api),
          TabMyRides(api: _api),
          TabInbox(api: _api),
          const TabProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
