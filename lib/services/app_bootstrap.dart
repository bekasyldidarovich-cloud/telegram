import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';
import 'auth_service.dart';
import 'chat_repository.dart';
import 'firebase_auth_service.dart';
import 'firebase_chat_repository.dart';
import 'local_auth_service.dart';
import 'local_chat_repository.dart';

class AppBootstrap {
  const AppBootstrap({
    required this.authService,
    required this.chatRepository,
    required this.usesFirebase,
    this.startupMessage,
  });

  final AuthService authService;
  final ChatRepository chatRepository;
  final bool usesFirebase;
  final String? startupMessage;
}

Future<AppBootstrap> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = DefaultFirebaseOptions.currentPlatform;
  if (!_optionsLookConfigured(options)) {
    return _localBootstrap(
      'Firebase options are not configured, so the app is running in local demo mode.',
    );
  }

  try {
    await Firebase.initializeApp(options: options);
    return AppBootstrap(
      authService: FirebaseAuthService(
        FirebaseAuth.instance,
        FirebaseFirestore.instance,
      ),
      chatRepository: FirebaseChatRepository(FirebaseFirestore.instance),
      usesFirebase: true,
    );
  } on Object catch (error) {
    return _localBootstrap(
      'Firebase could not start ($error), so the app is running in local demo mode.',
    );
  }
}

AppBootstrap _localBootstrap(String message) {
  return AppBootstrap(
    authService: LocalAuthService(),
    chatRepository: LocalChatRepository(),
    usesFirebase: false,
    startupMessage: message,
  );
}

bool _optionsLookConfigured(FirebaseOptions options) {
  final values = <String>[
    options.apiKey,
    options.appId,
    options.messagingSenderId,
    options.projectId,
  ];
  return values.every(
    (value) =>
        value.trim().isNotEmpty &&
        !value.contains('REPLACE_WITH') &&
        !value.contains('YOUR_'),
  );
}
