import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart' as home_ui;
import 'services/app_bootstrap.dart';
import 'state/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await bootstrapApp();
  runApp(TelegramCloneApp(bootstrap: bootstrap));
}

class TelegramCloneApp extends StatelessWidget {
  const TelegramCloneApp({required this.bootstrap, super.key});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authService: bootstrap.authService,
      chatRepository: bootstrap.chatRepository,
      usesFirebase: bootstrap.usesFirebase,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Telegram Clone',
        theme: _buildTheme(),
        home: _AuthGate(startupMessage: bootstrap.startupMessage),
      ),
    );
  }

  ThemeData _buildTheme() {
    const telegramBlue = Color(0xff229ed9);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: telegramBlue,
        primary: telegramBlue,
      ),
      scaffoldBackgroundColor: const Color(0xfff4f6f8),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: telegramBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff7f9fb),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffdfe5e9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffdfe5e9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: telegramBlue, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: telegramBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({this.startupMessage});

  final String? startupMessage;

  @override
  Widget build(BuildContext context) {
    final authService = AppScope.of(context).authService;

    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return AuthScreen(startupMessage: startupMessage);
        }

        return home_ui.HomeScreen(user: user);
      },
    );
  }
}
