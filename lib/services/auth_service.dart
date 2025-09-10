import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Thin wrapper around Firebase phone auth to match the methods
/// your screens already call.
class AuthService {
  static final AuthService _singleton = AuthService._();
  factory AuthService() => _singleton;
  AuthService._();

  final fb.FirebaseAuth _fa = fb.FirebaseAuth.instance;

  /// `null` if signed out
  String? get currentUserId => _fa.currentUser?.uid;

  /// Emits true/false when the signed-in state changes.
  Stream<bool> get signedInStream =>
      _fa.authStateChanges().map((u) => u != null);

  /// Start phone verification.
  /// Returns the verificationId you must keep to confirm the SMS code later.
  Future<String> startPhoneVerification(String phoneNumber) async {
    final completer = Completer<String>();

    await _fa.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential cred) async {
        // Auto-retrieval on some devices (optional sign-in here):
        try {
          await _fa.signInWithCredential(cred);
        } catch (_) {}
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // If timeout fires without codeSent first, still return the id
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  /// Confirm the OTP using the verificationId returned by startPhoneVerification.
  Future<fb.UserCredential> confirmSmsCode(
      String verificationId,
      String smsCode,
      ) async {
    final cred = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _fa.signInWithCredential(cred);
  }

  Future<void> signOut() => _fa.signOut();
}
