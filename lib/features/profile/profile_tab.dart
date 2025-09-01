// lib/features/profile/profile_tab.dart
import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Your Profile'),
            subtitle: Text('Link phone, KYC and vehicle here (coming soon)'),
          ),
        ],
      ),
    );
  }
}
