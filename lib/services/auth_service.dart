// lib/services/auth_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Unified auth utils for both Supabase + Firebase.
/// - Prefers Supabase user id for backend ownership
/// - Exposes a stream that emits on either auth system changes
class AuthService {
  static final AuthService _i = AuthService._();
  AuthService._();
  factory AuthService() => _i;

  final _supabase = sb.Supabase.instance;
  final _fb = fb.FirebaseAuth.instance;

  /// Emits whenever login state changes on Supabase OR Firebase.
  final StreamController<void> _signedInCtrl =
  StreamController<void>.broadcast();

  Stream<void> get signedInStream => _signedInCtrl.stream;

  void initListenersOnce() {
    // Call this once in main.dart after Supabase/Firebase init.
    // Supabase
    _supabase.client.auth.onAuthStateChange.listen((_) {
      _signedInCtrl.add(null);
    });
    // Firebase
    _fb.idTokenChanges().listen((_) {
      _signedInCtrl.add(null);
    });
  }

  /// Prefer Supabase user id; fall back to Firebase uid
  String? get currentUserId {
    final su = _supabase.client.auth.currentUser;
    if (su != null) return su.id;
    return _fb.currentUser?.uid;
  }

  String? get supabaseEmail => _supabase.client.auth.currentUser?.email;
  String? get firebasePhone => _fb.currentUser?.phoneNumber;

  Future<void> signOut() async {
    await Future.wait([
      _supabase.client.auth.signOut(),
      _fb.signOut(),
    ]);
    _signedInCtrl.add(null);
  }

  // ---------------- Firebase phone auth (OTP) ----------------

  /// Starts phone verification and returns verificationId you can use in confirmSmsCode.
  Future<String> startPhoneVerification(String e164Phone) async {
    final c = Completer<String>();
    await _fb.verifyPhoneNumber(
      phoneNumber: e164Phone,
      verificationCompleted: (fb.PhoneAuthCredential cred) async {
        // Auto-retrieval on some devices; sign in immediately
        await _fb.signInWithCredential(cred);
        if (!c.isCompleted) c.complete('AUTO'); // marker
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!c.isCompleted) c.completeError(e);
      },
      codeSent: (String verificationId, int? _) {
        if (!c.isCompleted) c.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String _) {
        if (!c.isCompleted) c.completeError(StateError('Code timeout'));
      },
    );
    return c.future;
  }

  /// Confirms the SMS code using a verificationId returned from startPhoneVerification.
  Future<void> confirmSmsCode(String verificationId, String smsCode) async {
    final cred = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _fb.signInWithCredential(cred);
  }

  // ---------------- Supabase account ops ----------------

  Future<void> updateSupabasePassword(String newPassword) async {
    await _supabase.client.auth.updateUser(
      sb.UserAttributes(password: newPassword),
    );
  }
}
