// lib/screens/tab_profile.dart
//
// Simple profile tab that fetches and displays the current user’s profile.
// The user can see their name, phone and address.  In a later iteration
// you can add editable fields or verification status indicators.  The
// profile is loaded from the backend via ApiClient.getProfile().

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';

class TabProfile extends StatefulWidget {
  final ApiClient api;
  const TabProfile({super.key, required this.api});

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _future = widget.api.getProfile(uid: userId);
  }

  // No need for _loadProfile; we call api.getProfile() directly in initState

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final profile = snap.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(profile['full_name'] ?? 'Unknown'),
              subtitle: const Text('Full name'),
            ),
            ListTile(
              title: Text(profile['phone'] ?? 'Unknown'),
              subtitle: const Text('Phone'),
            ),
            ListTile(
              title: Text(profile['address'] ?? 'Unknown'),
              subtitle: const Text('Address'),
            ),
            // Add more fields and statuses as needed
          ],
        );
      },
    );
  }
}