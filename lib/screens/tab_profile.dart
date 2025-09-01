// lib/screens/tab_profile.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TabProfile extends StatelessWidget {
  const TabProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Signed in as: ${user?.email ?? user?.id ?? 'unknown'}'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const Placeholder()),
                (_) => false,
              );
            },
            child: const Text('Sign out'),
          )
        ],
      ),
    );
  }
}
