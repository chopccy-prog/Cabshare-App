import 'package:flutter/material.dart';
import 'core/config_service.dart';
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
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _i = 0;
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
      body: _tabs[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
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
