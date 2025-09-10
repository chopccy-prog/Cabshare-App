import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({super.key, required this.api});
  final ApiClient api;

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Keep UI in sync with auth
    AuthService().signedInStream.listen((_) => _loadIfSignedIn());

    _loadIfSignedIn();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfSignedIn() async {
    final uid = AuthService().currentUserId;
    if (uid == null) {
      setState(() {
        _profile = null;
        _loading = false;
      });
      return;
    }
    await _loadProfile(uid);
  }

  Future<void> _loadProfile(String uid) async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getProfile(uid: uid);
      _profile = data;
      // seed controllers for simple editing
      _nameCtrl.text = (_profile?['full_name'] ?? '').toString();
      _phoneCtrl.text = (_profile?['phone'] ?? '').toString();
    } catch (_) {
      // keep previous _profile (may be null)
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    final fields = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };

    setState(() => _loading = true);
    try {
      final data = await widget.api.updateProfile(fields, uid: uid);
      setState(() {
        _profile = data;
        // refresh controllers from server response
        _nameCtrl.text = (_profile?['full_name'] ?? '').toString();
        _phoneCtrl.text = (_profile?['phone'] ?? '').toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      setState(() {
        _profile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Not signed in yet
    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please sign in to view your profile.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _signOut, // no-op if already signed out; leaves UI clean
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
    }

    // Signed in — show simple editable profile (keeps your behavior)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Your Profile',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Render any read-only data you were already showing:
        if (_profile!['email'] != null)
          Text('Email: ${_profile!['email']}'),
        if (_profile!['uid'] != null)
          Text('UID: ${_profile!['uid']}'),
      ],
    );
  }
}
