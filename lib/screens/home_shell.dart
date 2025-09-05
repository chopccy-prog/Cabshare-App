// lib/screens/home_shell.dart
//
// Revised home shell that accepts an [ApiClient] from the parent
// (typically main.dart) rather than constructing its own.  This
// ensures all tabs share the same API instance and bearer token.

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'tab_search.dart';
import 'tab_publish.dart';
import 'tab_my_rides.dart';
import 'tab_inbox.dart';
import 'tab_profile.dart';

class HomeShell extends StatefulWidget {
  final ApiClient api;
  const HomeShell({super.key, required this.api});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Cabshare')),
      body: IndexedStack(
        index: _idx,
        children: [
          TabSearch(api: api),
          TabPublish(api: api),
          TabMyRides(api: api),
          TabInbox(api: api),
          TabProfile(api: api),
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