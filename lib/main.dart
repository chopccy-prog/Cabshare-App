import 'package:flutter/material.dart';
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return const _CenteredPlaceholder(
      title: 'Inbox',
      subtitle: 'WhatsApp deeplink or in‑app chat (Phase 6)',
    );
  }
}


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return const _CenteredPlaceholder(
      title: 'Profile',
      subtitle: 'Login/Verification, Vehicle, Ratings (Phase 2/6)',
    );
  }
}


class _CenteredPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CenteredPlaceholder({required this.title, required this.subtitle});


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coming soon: $title')),
              ),
              child: const Text('Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}