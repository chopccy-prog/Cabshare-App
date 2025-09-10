import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPhonePage extends StatefulWidget {
  const LoginPhonePage({super.key});

  @override
  State<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends State<LoginPhonePage> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _verificationId;
  bool _sending = false;
  bool _verifying = false;

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone number')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final verificationId = await AuthService().startPhoneVerification(
        e164Phone: phone,
      );
      setState(() => _verificationId = verificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Send OTP first')),
      );
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter OTP')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      await AuthService().confirmSmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone login successful')),
        );
        Navigator.of(context).pop(true); // return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone number (+91XXXXXXXXXX)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _sendCode,
              child: _sending
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Send OTP'),
            ),
            const SizedBox(height: 24),
            if (_verificationId != null) ...[
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _verifying ? null : _verifyCode,
                child: _verifying
                    ? const CircularProgressIndicator.adaptive()
                    : const Text('Verify & Login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
