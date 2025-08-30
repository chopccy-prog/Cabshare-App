import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'features/search/search_tab.dart';
import 'features/publish/publish_tab.dart';
import 'features/rides/your_rides_tab.dart';
import 'features/inbox/inbox_tab.dart';
import 'features/profile/profile_tab.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _baseUrl = 'http://192.168.1.35:5000'; // <- your new Wi-Fi IP

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(baseUrl: _baseUrl);
    const currentUser = 'demo@cabshare.app'; // TODO: replace with real auth later

    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: _HomeShell(api: api, currentUser: currentUser),
    );
  }
}

class _HomeShell extends StatefulWidget {
  final ApiClient api;
  final String currentUser;
  const _HomeShell({required this.api, required this.currentUser});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      SearchTab(api: widget.api),
      PublishTab(api: widget.api),
      YourRidesTab(api: widget.api, currentUser: widget.currentUser),
      InboxTab(api: widget.api, currentUser: widget.currentUser),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_road), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
