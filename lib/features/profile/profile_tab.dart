import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // <- not const
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
