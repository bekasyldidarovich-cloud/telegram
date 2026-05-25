import '../models/app_user.dart';

typedef AppPhoneCodeSent = void Function(String verificationId);
typedef AppPhoneVerificationCompleted = void Function(AppUser user);
typedef AppPhoneVerificationFailed = void Function(String message);

abstract class AuthService {
  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  });

  Future<void> startPhoneSignIn({
    required String phoneNumber,
    required String displayName,
    required AppPhoneCodeSent onCodeSent,
    required AppPhoneVerificationCompleted onVerificationCompleted,
    required AppPhoneVerificationFailed onVerificationFailed,
  });

  Future<AppUser> confirmPhoneSignIn({
    required String verificationId,
    required String smsCode,
    required String displayName,
  });

  Future<void> updateProfile({
    required String displayName,
    String? phoneNumber,
  });

  Future<void> signOut();
}
