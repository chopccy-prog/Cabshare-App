// lib/main.dart
import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'features/search/search_tab.dart';
import 'features/publish/publish_tab.dart';
import 'features/rides/your_rides_tab.dart';
import 'features/inbox/inbox_tab.dart';
import 'features/profile/profile_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CabShare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // CHANGE THIS TO YOUR LAN BACKEND
  // e.g. http://192.168.1.35:5000
  final api = ApiClient(baseUrl: 'http://192.168.1.35:5000');

  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      SearchTab(api: api),
      PublishTab(api: api),
      YourRidesTab(api: api),
      InboxTab(api: api, currentUser: 'rider'), // 4th tab
      const ProfileTab(),                        // 5th tab
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),  // 4th
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
