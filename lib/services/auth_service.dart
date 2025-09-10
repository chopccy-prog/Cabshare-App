// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  Stream<User?> authChanges() => _fa.authStateChanges();

  Future<void> signOut() => _fa.signOut();

  Future<void> verifyPhone({
    required String phoneE164,
    required void Function(String verificationId) codeSent,
    required void Function(String error) onError,
  }) async {
    try {
      await _fa.verifyPhoneNumber(
        phoneNumber: phoneE164,
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _fa.signInWithCredential(cred);
        },
        verificationFailed: (FirebaseAuthException e) => onError(e.message ?? e.code),
        codeSent: (String verificationId, int? resendToken) => codeSent(verificationId),
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserCredential> submitOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _fa.signInWithCredential(cred);
  }
}
