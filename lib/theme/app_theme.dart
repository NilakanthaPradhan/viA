import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:via_app/services/storage_service.dart';

enum AppThemeType { defaultDark, midnight, neon, custom }

class ThemeProvider extends ChangeNotifier {
  AppThemeType _type;
  Color? _customColor;
  
  ThemeProvider(this._type) {
    if (_type == AppThemeType.custom) {
      final val = StorageService.getCustomThemeColor();
      if (val != null) {
        _customColor = Color(val);
      } else {
        _customColor = const Color(0xFF6C63FF); // Base fallback
      }
    }
    AppColors.setTheme(_type, customPrimary: _customColor);
  }

  AppThemeType get currentTheme => _type;

  void setTheme(AppThemeType type) {
    if (_type != type) {
      _type = type;
      StorageService.saveAppTheme(type.toString().split('.').last);
      AppColors.setTheme(type, customPrimary: _customColor);
      notifyListeners();
    }
  }

  void setCustomColor(Color color) {
    _customColor = color;
    _type = AppThemeType.custom;
    StorageService.saveAppTheme('custom');
    StorageService.saveCustomThemeColor(color.toARGB32());
    AppColors.setTheme(AppThemeType.custom, customPrimary: _customColor);
    notifyListeners();
  }

  Color get customColor => _customColor ?? const Color(0xFF6C63FF);
}

class _ColorPalette {
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color accentSecondary;
  final Color bgDark;
  final Color bgCard;
  final Color bgElevated;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;

  const _ColorPalette({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.accentSecondary,
    required this.bgDark,
    required this.bgCard,
    required this.bgElevated,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
  });
}

const _defaultDarkPalette = _ColorPalette(
  primary: Color(0xFF6C63FF),
  primaryDark: Color(0xFF4A42E8),
  accent: Color(0xFF00E5FF),
  accentSecondary: Color(0xFFFF6B9D),
  bgDark: Color(0xFF0A0E21),
  bgCard: Color(0xFF1A1F36),
  bgElevated: Color(0xFF252A42),
  surface: Color(0xFF161B2E),
  surfaceLight: Color(0xFF1E2440),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFB0B8D1),
  textMuted: Color(0xFF6B7394),
  success: Color(0xFF00E676),
  warning: Color(0xFFFFAB40),
  error: Color(0xFFFF5252),
);

const _midnightPalette = _ColorPalette(
  primary: Color(0xFF2196F3),
  primaryDark: Color(0xFF1976D2),
  accent: Color(0xFF00BCD4),
  accentSecondary: Color(0xFF9C27B0),
  bgDark: Color(0xFF000000),
  bgCard: Color(0xFF121212),
  bgElevated: Color(0xFF1E1E1E),
  surface: Color(0xFF0D0D0D),
  surfaceLight: Color(0xFF1F1F1F),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFB3B3B3),
  textMuted: Color(0xFF666666),
  success: Color(0xFF00C853),
  warning: Color(0xFFFF9100),
  error: Color(0xFFFF1744),
);

const _neonPalette = _ColorPalette(
  primary: Color(0xFFFF007F),
  primaryDark: Color(0xFFCC0066),
  accent: Color(0xFF00FFCC),
  accentSecondary: Color(0xFFCCFF00),
  bgDark: Color(0xFF0B0014),
  bgCard: Color(0xFF160029),
  bgElevated: Color(0xFF2B004D),
  surface: Color(0xFF140026),
  surfaceLight: Color(0xFF1D0038),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFFFCCF2),
  textMuted: Color(0xFF8B4D99),
  success: Color(0xFF39FF14),
  warning: Color(0xFFFFE600),
  error: Color(0xFFFF003C),
);

class AppColors {
  static _ColorPalette _currentPalette = _defaultDarkPalette;

  static void setTheme(AppThemeType type, {Color? customPrimary}) {
    switch (type) {
      case AppThemeType.midnight:
        _currentPalette = _midnightPalette;
        break;
      case AppThemeType.neon:
        _currentPalette = _neonPalette;
        break;
      case AppThemeType.custom:
        if (customPrimary != null) {
          _currentPalette = _generateCustomPalette(customPrimary);
        } else {
          _currentPalette = _defaultDarkPalette;
        }
        break;
      case AppThemeType.defaultDark:
        _currentPalette = _defaultDarkPalette;
        break;
    }
  }

  static _ColorPalette _generateCustomPalette(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    
    final primaryDark = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    final accentHsl = hsl.withHue((hsl.hue + 45) % 360).withLightness(0.65).withSaturation(0.9);
    final accent = accentHsl.toColor();
    final accentSecHsl = hsl.withHue((hsl.hue + 90) % 360).withLightness(0.6).withSaturation(0.85);
    final accentSecondary = accentSecHsl.toColor();

    final bgDark = hsl.withLightness(0.04).withSaturation(0.3).toColor();
    final bgCard = hsl.withLightness(0.08).withSaturation(0.25).toColor();
    final bgElevated = hsl.withLightness(0.12).withSaturation(0.2).toColor();
    
    final surface = hsl.withLightness(0.06).withSaturation(0.25).toColor();
    final surfaceLight = hsl.withLightness(0.10).withSaturation(0.25).toColor();

    final textPrimary = hsl.withLightness(0.95).withSaturation(0.1).toColor();
    final textSecondary = hsl.withLightness(0.75).withSaturation(0.15).toColor();
    final textMuted = hsl.withLightness(0.55).withSaturation(0.2).toColor();

    return _ColorPalette(
      primary: primary,
      primaryDark: primaryDark,
      accent: accent,
      accentSecondary: accentSecondary,
      bgDark: bgDark,
      bgCard: bgCard,
      bgElevated: bgElevated,
      surface: surface,
      surfaceLight: surfaceLight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      success: const Color(0xFF00E676),
      warning: const Color(0xFFFFAB40),
      error: const Color(0xFFFF5252),
    );
  }

  static Color get primary => _currentPalette.primary;
  static Color get primaryDark => _currentPalette.primaryDark;
  static Color get accent => _currentPalette.accent;
  static Color get accentSecondary => _currentPalette.accentSecondary;

  static Color get bgDark => _currentPalette.bgDark;
  static Color get bgCard => _currentPalette.bgCard;
  static Color get bgElevated => _currentPalette.bgElevated;

  static Color get surface => _currentPalette.surface;
  static Color get surfaceLight => _currentPalette.surfaceLight;

  static Color get textPrimary => _currentPalette.textPrimary;
  static Color get textSecondary => _currentPalette.textSecondary;
  static Color get textMuted => _currentPalette.textMuted;

  static Color get success => _currentPalette.success;
  static Color get warning => _currentPalette.warning;
  static Color get error => _currentPalette.error;

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [accentSecondary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkGradient => LinearGradient(
        colors: [bgDark, bgCard],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get glassGradient => const LinearGradient(
        colors: [
          Color(0x33FFFFFF),
          Color(0x0DFFFFFF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
