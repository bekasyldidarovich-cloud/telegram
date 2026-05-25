import 'dart:async';

import '../models/app_user.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  final Map<String, _LocalAccount> _accounts = <String, _LocalAccount>{};
  final Map<String, _LocalPhoneSession> _phoneSessions =
      <String, _LocalPhoneSession>{};

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _validateEmailAndPassword(normalizedEmail, password);

    final account = _accounts[normalizedEmail];
    if (account != null && account.password != password) {
      throw Exception('Wrong password. Please try again.');
    }

    final user =
        account?.user ??
        AppUser(
          id: 'local-${normalizedEmail.hashCode.abs()}',
          email: normalizedEmail,
          name: _nameFromEmail(normalizedEmail),
          avatarColor: _colorFor(normalizedEmail),
        );

    _accounts[normalizedEmail] = _LocalAccount(user: user, password: password);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final displayName = name.trim();
    _validateEmailAndPassword(normalizedEmail, password);

    if (displayName.length < 2) {
      throw Exception('Enter your name.');
    }

    final user = AppUser(
      id: 'local-${normalizedEmail.hashCode.abs()}',
      email: normalizedEmail,
      name: displayName,
      avatarColor: _colorFor(displayName),
    );
    _accounts[normalizedEmail] = _LocalAccount(user: user, password: password);
    _currentUser = user;
    _controller.add(user);
    return user;
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
    final name = displayName.trim().isEmpty
        ? _nameFromPhone(normalizedPhone)
        : displayName.trim();

    if (!_isValidPhone(normalizedPhone)) {
      onVerificationFailed(
        'Use international format, for example +77001234567.',
      );
      return;
    }

    final verificationId =
        'local-phone-${DateTime.now().microsecondsSinceEpoch}';
    _phoneSessions[verificationId] = _LocalPhoneSession(
      phoneNumber: normalizedPhone,
      displayName: name,
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    onCodeSent(verificationId);
  }

  @override
  Future<AppUser> confirmPhoneSignIn({
    required String verificationId,
    required String smsCode,
    required String displayName,
  }) async {
    final session = _phoneSessions[verificationId];
    if (session == null) {
      throw Exception(
        'The verification session has expired. Send the code again.',
      );
    }

    if (smsCode.trim() != '123456') {
      throw Exception('In local demo mode use SMS code 123456.');
    }

    final name = displayName.trim().isEmpty
        ? session.displayName
        : displayName.trim();
    final user = AppUser(
      id: 'local-phone-${session.phoneNumber.hashCode.abs()}',
      email: '',
      name: name,
      phoneNumber: session.phoneNumber,
      avatarColor: _colorFor(name),
    );
    _currentUser = user;
    _phoneSessions.remove(verificationId);
    _controller.add(user);
    return user;
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    final updatedUser = AppUser(
      id: user.id,
      email: user.email,
      name: displayName,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      avatarColor: _colorFor(displayName),
    );
    _currentUser = updatedUser;
    _controller.add(updatedUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }

  void _validateEmailAndPassword(String email, String password) {
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Enter a valid email address.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
  }

  bool _isValidPhone(String phoneNumber) {
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber);
  }

  String _nameFromPhone(String phoneNumber) {
    if (phoneNumber.length <= 4) {
      return 'Telegram User';
    }
    return 'User ${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  String _nameFromEmail(String email) {
    final userName = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = userName.split(' ').where((part) => part.isNotEmpty);
    if (words.isEmpty) {
      return 'Telegram User';
    }
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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
}

class _LocalAccount {
  const _LocalAccount({required this.user, required this.password});

  final AppUser user;
  final String password;
}

class _LocalPhoneSession {
  const _LocalPhoneSession({
    required this.phoneNumber,
    required this.displayName,
  });

  final String phoneNumber;
  final String displayName;
}
