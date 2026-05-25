import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  AppUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.userChanges().map(_mapUser);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) {
        throw Exception('Could not sign in.');
      }
      await _upsertUserProfile(credential.user);
      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageForAuthError(error));
    }
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();

      final user = _mapUser(_firebaseAuth.currentUser ?? credential.user);
      if (user == null) {
        throw Exception('Could not create account.');
      }
      await _upsertUserProfile(credential.user, displayName: name);
      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageForAuthError(error));
    }
  }

  @override
  Future<void> startPhoneSignIn({
    required String phoneNumber,
    required String displayName,
    required AppPhoneCodeSent onCodeSent,
    required AppPhoneVerificationCompleted onVerificationCompleted,
    required AppPhoneVerificationFailed onVerificationFailed,
  }) async {
    final normalizedPhone = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
    if (!_isValidPhone(normalizedPhone)) {
      onVerificationFailed(
        'Use international format, for example +77001234567.',
      );
      return;
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) async {
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(
              credential,
            );
            final user = await _completePhoneSignIn(
              userCredential.user,
              displayName: displayName,
            );
            onVerificationCompleted(user);
          } on Object catch (error) {
            onVerificationFailed(
              error.toString().replaceFirst('Exception: ', ''),
            );
          }
        },
        verificationFailed: (error) {
          onVerificationFailed(_messageForAuthError(error));
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (error) {
      onVerificationFailed(_messageForAuthError(error));
    } on Object catch (error) {
      onVerificationFailed(error.toString());
    }
  }

  @override
  Future<AppUser> confirmPhoneSignIn({
    required String verificationId,
    required String smsCode,
    required String displayName,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return _completePhoneSignIn(
        userCredential.user,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageForAuthError(error));
    }
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateDisplayName(displayName);
    await _upsertUserProfile(user, displayName: displayName);
    await user.reload();
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<AppUser> _completePhoneSignIn(
    User? firebaseUser, {
    required String displayName,
  }) async {
    if (firebaseUser == null) {
      throw Exception('Could not sign in with this phone number.');
    }

    final trimmedName = displayName.trim();
    if (trimmedName.isNotEmpty && firebaseUser.displayName != trimmedName) {
      await firebaseUser.updateDisplayName(trimmedName);
      await firebaseUser.reload();
    }

    final reloadedUser = _firebaseAuth.currentUser ?? firebaseUser;
    await _upsertUserProfile(reloadedUser, displayName: trimmedName);
    final user = _mapUser(_firebaseAuth.currentUser ?? reloadedUser);
    if (user == null) {
      throw Exception('Could not sign in with this phone number.');
    }
    return user;
  }

  Future<void> _upsertUserProfile(User? user, {String? displayName}) async {
    if (user == null) {
      return;
    }

    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final name = _displayNameFor(user, override: displayName);
    final data = <String, dynamic>{
      'id': user.uid,
      'displayName': name,
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'phoneSearchKey': _phoneSearchKey(user.phoneNumber ?? ''),
      'photoUrl': user.photoURL,
      'avatarColor': _colorFor(name),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await doc.set(data, SetOptions(merge: true));
  }

  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    final displayName = _displayNameFor(user);
    final email = user.email ?? '';
    return AppUser(
      id: user.uid,
      email: email,
      name: displayName,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      avatarColor: _colorFor(displayName),
    );
  }

  String _displayNameFor(User user, {String? override}) {
    final preferred = override?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email ?? '';
    if (email.isNotEmpty) {
      return _nameFromEmail(email);
    }

    final phone = user.phoneNumber ?? '';
    if (phone.length > 4) {
      return 'User ${phone.substring(phone.length - 4)}';
    }

    return 'Telegram User';
  }

  String _nameFromEmail(String email) {
    if (!email.contains('@')) {
      return 'Telegram User';
    }
    final userName = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = userName.split(' ').where((part) => part.isNotEmpty);
    if (words.isEmpty) {
      return 'Telegram User';
    }
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  bool _isValidPhone(String phoneNumber) {
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber);
  }

  String _phoneSearchKey(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  int _colorFor(String input) {
    const colors = <int>[
      0xff54a9eb,
      0xff40b97c,
      0xfff59b42,
      0xffe56b6f,
      0xff8e77ed,
      0xff19a7a8,
    ];
    return colors[input.hashCode.abs() % colors.length];
  }

  String _messageForAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-phone-number':
        return 'Enter a valid phone number in international format.';
      case 'missing-client-identifier':
      case 'captcha-check-failed':
        return 'Phone sign-in could not verify this app. Check SHA-1/SHA-256 and Firebase phone auth settings.';
      case 'invalid-verification-code':
        return 'The SMS code is incorrect.';
      case 'session-expired':
        return 'The SMS code expired. Send a new code.';
      case 'quota-exceeded':
      case 'too-many-requests':
        return 'SMS limit reached. Wait a bit or use a Firebase test phone number.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Try again.';
    }
  }
}
