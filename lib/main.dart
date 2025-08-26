import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CabshareApp());
}

class CabshareApp extends StatelessWidget {
  const CabshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  final _pages = const [
    SearchScreen(),
    PublishScreen(),
    YourRidesScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// Placeholders – will wire to real flows
class SearchScreen extends StatelessWidget { const SearchScreen({super.key});
@override Widget build(BuildContext ctx) => const Center(child: Text('Search rides'));
}
class PublishScreen extends StatelessWidget { const PublishScreen({super.key});
@override Widget build(BuildContext ctx) => const Center(child: Text('Publish ride'));
}
class YourRidesScreen extends StatelessWidget { const YourRidesScreen({super.key});
@override Widget build(BuildContext ctx) => const Center(child: Text('Your rides'));
}
class InboxScreen extends StatelessWidget { const InboxScreen({super.key});
@override Widget build(BuildContext ctx) => const Center(child: Text('Inbox / WhatsApp'));
}
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key});
@override Widget build(BuildContext ctx) => const Center(child: Text('Profile & Login'));
}
