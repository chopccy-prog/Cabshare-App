import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'login_phone.dart';

class TabProfile extends StatefulWidget {
  final ApiClient api;
  const TabProfile({super.key, required this.api});

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  // Form state
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addrC = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _err;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadIfSignedIn();
    // Rebuild when auth state changes (e.g., after phone login)
    AuthService().signedInStream.listen((_) => _loadIfSignedIn());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameC.dispose();
    _phoneC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  Future<void> _loadIfSignedIn() async {
    final uid = AuthService().currentUserId;
    if (uid == null) {
      // Not logged in; just show the sign-in CTA
      if (mounted) {
        setState(() {
          _loading = false;
          _profile = null;
          _nameC.text = '';
          _phoneC.text = '';
          _addrC.text = '';
          _err = null;
        });
      }
      return;
    }
    await _loadProfile(uid);
  }

  Future<void> _loadProfile(String uid) async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final p = await widget.api.getProfile(uid: uid);
      _profile = p ?? {'user_id': uid};
      _nameC.text = (_profile?['full_name'] ?? '').toString();
      _phoneC.text = (_profile?['phone'] ?? '').toString();
      _addrC.text = (_profile?['address'] ?? '').toString();
    } catch (e) {
      _err = 'Failed to load profile: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = AuthService().currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      final updated = await widget.api.updateProfile({
        'full_name': _nameC.text.trim(),
        'phone': _phoneC.text.trim(),
        'address': _addrC.text.trim(),
      }, uid: uid);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } catch (e) {
      setState(() => _err = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPhoneLogin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPhonePage()),
    );
    if (ok == true || AuthService().currentUserId != null) {
      final uid = AuthService().currentUserId!;
      await _loadProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'About you'),
            Tab(text: 'Account'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabs,
        children: [
          // ===== About you =====
          uid == null ? _buildSignedOut() : _buildAboutYou(),
          // ===== Account =====
          uid == null ? _buildSignedOut() : _buildAccount(),
        ],
      ),
    );
  }

  // When not signed-in: show the phone login CTA
  Widget _buildSignedOut() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_iphone, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Sign in to manage your profile,\nvehicles, rides and bookings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _openPhoneLogin,
              child: const Text('Continue with Phone'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutYou() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameC,
          decoration: const InputDecoration(labelText: 'Full name *'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneC,
          decoration: const InputDecoration(labelText: 'Phone *'),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addrC,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
        const SizedBox(height: 16),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_err!, style: const TextStyle(color: Colors.red)),
          ),
        FilledButton(
          onPressed: _saving ? null : _saveProfile,
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text('Vehicles',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Vehicle add/verify can be completed from Admin for now. '
              'We will wire this screen after you confirm table/column names.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('Password'),
          subtitle: const Text('Change your password'),
          onTap: () {
            // Optional: navigate to your password screen if you keep email auth too
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change coming soon')),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: const Text('Payments & refunds'),
          subtitle: const Text('Deposits, cancellations, payouts'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                  Text('We will link Razorpay screens in a later step')),
            );
          },
        ),
        const SizedBox(height: 24),
        // Logout button (explicit at the bottom of Account tab)
        TextButton.icon(
          onPressed: () async {
            try {
              await AuthService().signOut();
            } catch (_) {}
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signed out')),
            );
            setState(() {
              _profile = null;
              _nameC.text = '';
              _phoneC.text = '';
              _addrC.text = '';
            });
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}
