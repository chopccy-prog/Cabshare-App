import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'tab_search.dart';
import 'tab_publish.dart';
import 'tab_my_rides.dart';
import 'tab_inbox.dart';
import 'tab_profile.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});
  final ApiClient api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      TabSearch(api: widget.api),
      TabPublish(api: widget.api),
      TabMyRides(api: widget.api),
      TabInbox(api: widget.api),
      TabProfile(api: widget.api), // <-- pass api (fixes compile error)
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
