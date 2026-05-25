import 'package:flutter/widgets.dart';

import '../services/auth_service.dart';
import '../services/chat_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    required this.authService,
    required this.chatRepository,
    required this.usesFirebase,
    required super.child,
    super.key,
  });

  final AuthService authService;
  final ChatRepository chatRepository;
  final bool usesFirebase;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return authService != oldWidget.authService ||
        chatRepository != oldWidget.chatRepository ||
        usesFirebase != oldWidget.usesFirebase;
  }
}
