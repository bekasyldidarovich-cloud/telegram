import 'package:flutter_test/flutter_test.dart';

import 'package:telegram_clone/main.dart';
import 'package:telegram_clone/services/app_bootstrap.dart';
import 'package:telegram_clone/services/local_auth_service.dart';
import 'package:telegram_clone/services/local_chat_repository.dart';

void main() {
  testWidgets('shows phone authentication screen', (WidgetTester tester) async {
    final bootstrap = AppBootstrap(
      authService: LocalAuthService(),
      chatRepository: LocalChatRepository(),
      usesFirebase: false,
    );

    await tester.pumpWidget(TelegramCloneApp(bootstrap: bootstrap));
    await tester.pump();

    expect(find.text('Your phone number'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
  });
}
