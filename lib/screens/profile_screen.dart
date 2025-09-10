// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late final TabController _tab;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  // change password
  final _pwd1 = TextEditingController();
  final _pwd2 = TextEditingController();

  bool _saving = false;
  String? _err;

  List<Map<String, dynamic>> _vehicles = [];
  bool _vehLoading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadVehicles();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      final rows = await _client
          .from('profiles')
          .select('full_name, phone, address, aadhaar_verified, vehicle_verified, license_verified, docs_verified')
          .eq('user_id', uid)
          .limit(1);

      if (rows is List && rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        _nameCtrl.text = (row['full_name'] ?? '').toString();
        _phoneCtrl.text = (row['phone'] ?? '').toString();
        _addrCtrl.text = (row['address'] ?? '').toString();
      } else {
        _nameCtrl.text = '';
        _phoneCtrl.text = '';
        _addrCtrl.text = '';
      }
    } catch (e) {
      setState(() => _err = e.toString());
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => _vehLoading = true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      final rows = await _client
          .from('vehicles')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      setState(() =>
      _vehicles = List<Map<String, dynamic>>.from(rows ?? const []));
    } catch (_) {
      setState(() => _vehicles = const []);
    } finally {
      setState(() => _vehLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _err = null; });
    try {
      final uid = _client.auth.currentUser!.id;
      final payload = {
        'user_id': uid,
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').upsert(payload, onConflict: 'user_id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      setState(() => _err = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addVehicleDialog() async {
    final make = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();
    final plate = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: make,  decoration: const InputDecoration(labelText: 'Make (e.g., Hyundai)')),
            TextField(controller: model, decoration: const InputDecoration(labelText: 'Model (e.g., i20)')),
            TextField(controller: color, decoration: const InputDecoration(labelText: 'Color')),
            TextField(controller: plate, decoration: const InputDecoration(labelText: 'Plate no')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final uid = _client.auth.currentUser!.id;
      await _client.from('vehicles').insert({
        'user_id': uid,
        'make': make.text.trim(),
        'model': model.text.trim(),
        'color': color.text.trim(),
        'plate_no': plate.text.trim(),
        'verified': false,
      });
      await _loadVehicles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle added')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  Future<void> _changePassword() async {
    if (_pwd1.text.isEmpty || _pwd1.text != _pwd2.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: _pwd1.text));
      _pwd1.clear(); _pwd2.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password change failed: $e')));
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _pwd1.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _client.auth.currentUser?.email ?? '';
    final phoneAuth = _client.auth.currentUser?.phone ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'About you'), Tab(text: 'Account')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ABOUT YOU
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (email.isNotEmpty) Text('Email: $email'),
              if (phoneAuth.isNotEmpty) Text('Phone (auth): $phoneAuth'),
              if (_err != null) ...[
                const SizedBox(height: 8),
                Text(_err!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              TextField(controller: _nameCtrl,  decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
              const SizedBox(height: 24),
              Text('Vehicles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_vehLoading) const LinearProgressIndicator(),
              if (!_vehLoading && _vehicles.isEmpty) const Text('No vehicles yet'),
              for (final v in _vehicles)
                Card(
                  child: ListTile(
                    title: Text(
                        '${(v['make'] ?? '').toString()} ${(v['model'] ?? '').toString()}'.trim().isEmpty
                            ? 'Vehicle'
                            : '${(v['make'] ?? '').toString()} ${(v['model'] ?? '').toString()}'
                    ),
                    subtitle: Text('Color: ${(v['color'] ?? '-')}  •  Plate: ${(v['plate_no'] ?? '-')}'),
                    trailing: (v['verified'] == true)
                        ? const Icon(Icons.verified, color: Colors.green)
                        : const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _addVehicleDialog, child: const Text('Add vehicle')),
            ],
          ),

          // ACCOUNT
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Change password'),
              const SizedBox(height: 8),
              TextField(controller: _pwd1, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
              const SizedBox(height: 8),
              TextField(controller: _pwd2, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _changePassword, child: const Text('Update password')),

              const SizedBox(height: 24),
              const Divider(),
              const ListTile(title: Text('Payment methods'), trailing: Icon(Icons.chevron_right)),
              const Divider(height: 0),
              const ListTile(title: Text('Ratings'), trailing: Icon(Icons.chevron_right)),
            ],
          ),
        ],
      ),
    );
  }
}
