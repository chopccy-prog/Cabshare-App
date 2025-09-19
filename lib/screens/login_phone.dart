import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'home_shell.dart';

class LoginPhone extends StatefulWidget {
  final ApiClient api;
  
  const LoginPhone({super.key, required this.api});

  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _verificationId;
  bool _sending = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    try {
      final id = await AuthService().startPhoneVerification(_phoneCtrl.text.trim());
      setState(() => _verificationId = id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code sent')),
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

  Future<void> _confirm() async {
    if (_verificationId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Send code first')));
      return;
    }
    setState(() => _sending = true);
    try {
      await AuthService().confirmSmsCode(_verificationId!, _otpCtrl.text.trim());
      if (mounted) {
        // Navigate to home on successful verification
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeShell(api: widget.api),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verify failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final haveCode = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!haveCode) ...[
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone (+91… E.164)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending ? null : _sendCode,
                child: Text(_sending ? 'Sending…' : 'Send code'),
              ),
            ] else ...[
              TextField(
                controller: _otpCtrl,
                decoration: const InputDecoration(labelText: 'OTP'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending ? null : _confirm,
                child: Text(_sending ? 'Verifying…' : 'Verify'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}