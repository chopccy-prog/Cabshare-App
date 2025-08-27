import 'package:flutter/material.dart';
import 'features/search/search_tab.dart';
import 'features/publish/publish_tab.dart';
import 'features/rides/your_rides_tab.dart';
import 'features/inbox/inbox_tab.dart';
import 'features/profile/profile_tab.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const HomeScaffold(),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});
  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _ix = 0;
  final _tabs = const [
    SearchTab(),
    PublishTab(),
    YourRidesTab(),
    InboxTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_ix],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _ix,
        onDestinationSelected: (i) => setState(() => _ix = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Rides'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
