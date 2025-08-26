import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global crash guard so startup exceptions don't kill the isolate silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  runZonedGuarded(() {
    runApp(const RealApp());
  }, (error, stack) {
    debugPrint('[ZoneError] $error\n$stack');
  });
}

class RealApp extends StatelessWidget {
  const RealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabshare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const AppHome(),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this placeholder with your real home screen / navigator.
    return Scaffold(
      appBar: AppBar(title: const Text('Cabshare')),
      body: const Center(child: Text('App shell running')),
    );
  }
}
