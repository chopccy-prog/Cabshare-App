import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPhone extends StatefulWidget {
  const LoginPhone({super.key});

  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _verificationId;
  bool _sending = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    try {
      final vId = await AuthService().startPhoneVerification(_phoneCtrl.text.trim());
      setState(() => _verificationId = vId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    final vId = _verificationId;
    if (vId == null) return;
    setState(() => _sending = true);
    try {
      await AuthService().confirmSmsCode(vId, _codeCtrl.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirm failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVerificationId = _verificationId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (+91...)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            if (hasVerificationId)
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'OTP Code'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : (hasVerificationId ? _confirm : _sendCode),
              child: Text(_sending
                  ? 'Please wait...'
                  : (hasVerificationId ? 'Confirm Code' : 'Send Code')),
            ),
          ],
        ),
      ),
    );
  }
}
