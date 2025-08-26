import 'package:flutter/material.dart';

// Tabs (keep these imports if the files exist; otherwise create the tabs as we scaffolded)
import 'features/search/search_tab.dart';
import 'features/publish/publish_tab.dart';
import 'features/rides/your_rides_tab.dart';
import 'features/inbox/inbox_tab.dart';
import 'features/profile/profile_tab.dart';

/// Simple app-wide config you can read anywhere through:
///   final cfg = AppConfig.of(context);
///   cfg.baseUrl
class AppConfig extends InheritedWidget {
  const AppConfig({
    super.key,
    required this.baseUrl,
    required Widget child,
  }) : super(child: child);

  /// Default points to your LAN server; override with
  ///   --dart-define=API_BASE=http://<your-ip>:5000
  final String baseUrl;

  static AppConfig of(BuildContext context) {
    final AppConfig? result = context.dependOnInheritedWidgetOfExactType<AppConfig>();
    assert(result != null, 'No AppConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppConfig oldWidget) => baseUrl != oldWidget.baseUrl;
}

void main() {
  // Allow overriding at build time without editing code.
  const base = String.fromEnvironment('API_BASE', defaultValue: 'http://192.168.1.7:5000');
  runApp(AppConfig(baseUrl: base, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const _MainShell(),
    );
  }
}

/// Bottom-nav shell that keeps tab state with an IndexedStack.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  late final List<Widget> _tabs = const <Widget>[
    SearchTab(),
    PublishTab(),
    YourRidesTab(),
    InboxTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Each tab is preserved (no rebuilds when switching).
      body: SafeArea(child: IndexedStack(index: _index, children: _tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Your Rides'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
