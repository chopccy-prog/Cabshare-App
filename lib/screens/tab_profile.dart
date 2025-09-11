// lib/screens/tab_profile.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/profile_repo.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({super.key, required this.api});
  final ApiClient api;

  @override
  State<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _repo = ProfileRepo();
  late final TabController _tabs;

  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _kyc = [];

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Payments
  int _balanceInr = 0;
  List<Map<String, dynamic>> _txns = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this); // Profile, Account, Payments
    _auth.initListenersOnce();
    _auth.signedInStream.listen((_) => _loadAll());
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final p = await _repo.getMyProfile();
      final v = await _repo.myVehicles();
      final k = await _repo.myKycDocs();

      _profile = p;
      _vehicles = v;
      _kyc = k;

      _nameCtrl.text = p?['full_name'] ?? '';
      _phoneCtrl.text = p?['phone'] ?? _auth.firebasePhone ?? '';

      try {
        _balanceInr = await widget.api.getWalletBalance();
        _txns = await widget.api.getTransactions();
      } catch (_) {
        _balanceInr = 0;
        _txns = const [];
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final email = AuthService().supabaseEmail;
    final updated = await _repo.upsertMyProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: email,
    );
    setState(() => _profile = updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  Future<void> _addVehicleDialog() async {
    final plate = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plate,
              decoration: const InputDecoration(labelText: 'Plate'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: color,
              decoration: const InputDecoration(labelText: 'Color (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _repo.addVehicle(
        plate: plate.text.trim(),
        model: model.text.trim(),
        color: color.text.trim(),
      );
      await _loadAll();
    }
  }

  Future<void> _deleteVehicle(int id) async {
    await _repo.deleteVehicle(id);
    await _loadAll();
  }

  // Upload helpers
  Future<void> _uploadDoc({
    required String docType,
    required Future<({Uint8List bytes, String filename})?> Function() pick,
  }) async {
    final picked = await pick();
    if (picked == null) return;
    await _repo.uploadKycDocument(docType: docType, bytes: picked.bytes, filename: picked.filename);
    await _loadAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploaded $docType')),
    );
  }

  // Stub picker – replace with file_picker if you enable it in pubspec.yaml
  Future<({Uint8List bytes, String filename})?> _pickWithFilePicker() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add file_picker to enable uploads')),
      );
    }
    return null;
  }

  // Payments actions
  Future<void> _addFunds() async {
    try {
      await widget.api.createTopUpIntent(500);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up initiated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Top-up failed: $e')));
    }
  }

  Future<void> _withdraw() async {
    try {
      await widget.api.requestPayout(500);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payout failed: $e')));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kycStatus = (_profile?['kyc_status'] ?? 'unverified').toString();
    final email = AuthService().supabaseEmail ?? '—';
    final phone = AuthService().firebasePhone ?? _profile?['phone'] ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Account'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabs,
        children: [
          // ---------------- PROFILE TAB ----------------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text('Phone: $phone', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: kycStatus == 'verified'
                          ? Colors.green.withOpacity(.1)
                          : Colors.orange.withOpacity(.1),
                      border: Border.all(
                        color: kycStatus == 'verified' ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      kycStatus == 'verified' ? 'Government Verified' : 'Not Verified',
                      style: TextStyle(
                        color: kycStatus == 'verified' ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                decoration: const InputDecoration(
                  labelText: 'Phone (E.164)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: _saveProfile, child: const Text('Save')),
              ),
              const SizedBox(height: 24),
              Text('Vehicles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._vehicles.map((v) => Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v['model']?.toString() ?? 'Vehicle'),
                  subtitle: Text(
                    'Plate: ${v['plate'] ?? '—'}'
                        '${v['color'] != null ? ' • ${v['color']}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteVehicle(v['id'] as int),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addVehicleDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add vehicle'),
              ),
              const SizedBox(height: 24),
              Text('Documents (for admin verification)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _docRow('ID Proof', 'id_proof'),
              _docRow('Driver License', 'driver_license'),
              _docRow('Vehicle RC', 'vehicle_rc'),
              const SizedBox(height: 8),
              Text(
                'Note: After admin marks as verified, documents will be purged periodically from storage.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          // ---------------- ACCOUNT TAB ----------------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Login methods', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Supabase email/password'),
                subtitle: Text(email),
              ),
              const SizedBox(height: 8),
              _ChangePasswordCard(),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Firebase phone (OTP)'),
                subtitle: Text(AuthService().firebasePhone ?? 'Not linked'),
                trailing: OutlinedButton(
                  onPressed: _linkPhoneFlow,
                  child: const Text('Link / Update'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _auth.signOut();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                },
                label: const Text('Sign out'),
              ),
            ],
          ),

          // ---------------- PAYMENTS TAB ----------------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text('Deposit balance', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: Text('₹ $_balanceInr'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(onPressed: _addFunds, child: const Text('Add funds')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: _withdraw, child: const Text('Withdraw')),
                ],
              ),
              const SizedBox(height: 20),
              Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              if (_txns.isEmpty)
                const Text('No transactions yet')
              else
                ..._txns.map((t) => ListTile(
                  leading: Icon(
                    (t['amount_inr'] ?? 0) >= 0 ? Icons.call_received : Icons.call_made,
                  ),
                  title: Text('₹ ${t['amount_inr']}'),
                  subtitle: Text(t['description']?.toString() ?? ''),
                  trailing: Text(
                    (t['status'] ?? 'ok').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docRow(String label, String type) {
    final latest = _kyc.firstWhere(
          (e) => e['doc_type'] == type,
      orElse: () => const {},
    );
    final status = (latest['status'] ?? 'none').toString();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(label),
        subtitle: Text('Status: $status'),
        trailing: OutlinedButton(
          onPressed: () => _uploadDoc(docType: type, pick: _pickWithFilePicker),
          child: const Text('Upload'),
        ),
      ),
    );
  }

  Future<void> _linkPhoneFlow() async {
    final phoneCtrl = TextEditingController(text: _phoneCtrl.text);
    final codeCtrl = TextEditingController();
    String? verificationId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link phone (OTP)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (E.164)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    try {
                      verificationId = await _auth.startPhoneVerification(phoneCtrl.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code sent')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Send code'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Enter code'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verify')),
        ],
      ),
    );

    if (ok == true) {
      try {
        final vid = verificationId;
        if (vid == null || vid == 'AUTO') {
          // Either auto-verified or not requested
        } else {
          await _auth.confirmSmsCode(vid, codeCtrl.text.trim());
        }
        await _repo.upsertMyProfile(phone: phoneCtrl.text.trim());
        await _loadAll();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone linked')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verify failed: $e')));
      }
    }
  }
}

class _ChangePasswordCard extends StatefulWidget {
  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _pwd1 = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pwd1.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text('Change Supabase password', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pwd1,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pwd2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pwd1.text != _pwd2.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService().updateSupabasePassword(_pwd1.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      _pwd1.clear();
      _pwd2.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
