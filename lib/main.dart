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
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
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
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
