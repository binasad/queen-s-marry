import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String phone;
  const VerifyPhoneScreen({super.key, required this.phone});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _smsController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _status;

  String _toE164(String local) {
    // Convert Pakistani local format 03XXXXXXXXX to +923XXXXXXXXX
    final cleaned = local.replaceAll(RegExp(r'[^0-9]'), '');
    if (RegExp(r'^03\d{9}$').hasMatch(cleaned)) {
      return '+92' + cleaned.substring(1); // drop leading 0
    }
    // If already in E.164, return as-is
    if (RegExp(r'^\+92\d{10}$').hasMatch(local)) {
      return local;
    }
    return local; // fallback
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    final phoneNumber = _toE164(widget.phone);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification (Android)
          await _linkCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _status = 'Failed: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
            _status = 'Code sent to ${widget.phone}';
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          setState(() {
            _status = 'Auto-retrieval timed out';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _confirmCode() async {
    if (_verificationId == null) return;
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsController.text.trim(),
      );
      await _linkCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _status = e.message;
      });
    }
  }

  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _status = 'User not logged in';
      });
      return;
    }
    try {
      await user.linkWithCredential(credential);
      // Mark phoneVerified in DB
      await FirebaseDatabase.instance.ref('Users/${user.uid}').update({
        'phoneVerified': true,
      });
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // If already linked to another account
      setState(() {
        _status = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${widget.phone}'),
            const SizedBox(height: 12),
            // reCAPTCHA container for web
            if (kIsWeb && !_codeSent)
              Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                child: const Text(
                  'Complete reCAPTCHA verification below to send code',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (!_codeSent)
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Send Code'),
              ),
            if (_codeSent) ...[
              TextField(
                controller: _smsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmCode,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Confirm'),
              ),
            ],
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!, style: const TextStyle(color: Colors.blue)),
            ],
          ],
        ),
      ),
    );
  }
}
