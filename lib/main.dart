import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/services/storage_service.dart';
import 'package:via_app/screens/welcome_screen.dart';
import 'package:via_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await StorageService.init();

  // Check if user has already seen the welcome screen
  final bool showWelcome = !StorageService.hasSeenWelcome();

  runApp(ViAApp(showWelcome: showWelcome));
}

class ViAApp extends StatelessWidget {
  final bool showWelcome;
  const ViAApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'viA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: showWelcome ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}
