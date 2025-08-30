import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'features/search/search_tab.dart';
import 'features/inbox/inbox_tab.dart';
import 'features/publish/publish_tab.dart';
import 'features/rides/your_rides_tab.dart';
import 'features/profile/profile_tab.dart';

void main() {
  runApp(const CabshareApp());
}

class CabshareApp extends StatelessWidget {
  const CabshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
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
  late final ApiClient api;
  final String currentUser = 'rider'; // replace with real identity later
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    api = ApiClient(baseUrl: 'http://192.168.1.35:5000'); // LAN server
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SearchTab(api: api),
      InboxTab(api: api, currentUser: currentUser),
      PublishTab(api: api),
      YourRidesTab(api: api),
      const ProfileTab(), // <— now visible
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your rides'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
