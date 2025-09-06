// lib/screens/tab_profile.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';
import 'login_page.dart';

class TabProfile extends StatefulWidget {
  final ApiClient api;
  const TabProfile({super.key, required this.api});
  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final prof = await widget.api.getProfile(uid: uid);
      setState(() {
        _profile = prof;
        _nameCtrl.text = prof['full_name'] ?? '';
        _phoneCtrl.text = prof['phone'] ?? '';
        _addrCtrl.text = prof['address'] ?? '';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fields = {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
      };
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final updated = await widget.api.updateProfile(fields, uid: uid);
      setState(() {
        _profile = updated;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;
    final email = authUser?.email ?? '';
    final phoneAuth = authUser?.phone ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (authUser != null) ...[
            Text('Email: $email'),
            if (phoneAuth.isNotEmpty) Text('Phone (auth): $phoneAuth'),
          ] else ...[
            const Text('Not signed in'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(api: widget.api),
                  ),
                );
              },
              child: const Text('Sign in'),
            ),
          ],
          const SizedBox(height: 16),
          _loading
              ? const CircularProgressIndicator()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Aadhaar verified: ${_profile['is_aadhaar_verified'] == true ? 'Yes' : 'No'}'),
                  const SizedBox(width: 16),
                  Text('Vehicle verified: ${_profile['is_vehicle_verified'] == true ? 'Yes' : 'No'}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('License verified: ${_profile['is_license_verified'] == true ? 'Yes' : 'No'}'),
                  const SizedBox(width: 16),
                  Text('Docs verified: ${_profile['is_doc_verified'] == true ? 'Yes' : 'No'}'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveProfile,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (authUser != null)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          widget.api.setAuthToken(null);
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LoginPage(api: widget.api),
                              ),
                            );
                          }
                        },
                        child: const Text('Log out'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
