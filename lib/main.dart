import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/services/storage_service.dart';
import 'package:via_app/screens/welcome_screen.dart';
import 'package:via_app/screens/home_screen.dart';

late final ThemeProvider themeProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  themeProvider = ThemeProvider(AppThemeType.defaultDark);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Check if user has already seen the welcome screen
  final bool showWelcome = !StorageService.hasSeenWelcome();

  runApp(ViAApp(showWelcome: showWelcome));
}

class ViAApp extends StatelessWidget {
  final bool showWelcome;
  const ViAApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'viA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: showWelcome ? const WelcomeScreen() : const HomeScreen(),
        );
      },
    );
  }
}
