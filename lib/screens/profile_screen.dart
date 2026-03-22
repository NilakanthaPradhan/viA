import 'package:flutter/material.dart';
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/services/storage_service.dart';
import 'package:via_app/utils/distance_calculator.dart';
import 'package:via_app/widgets/glass_container.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:via_app/main.dart'; // Access themeProvider

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = StorageService.getStats();
    final totalDistance = stats['totalDistance'] as double;
    final totalSteps = stats['totalSteps'] as int;
    final totalCalories = stats['totalCalories'] as double;
    final totalRoutes = stats['totalRoutes'] as int;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120), // Added bottom padding to make App info scrollable above bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Avatar card
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'viA',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Explorer',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Path walker & distance tracker',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // All-time stats
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'ALL-TIME STATS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats cards
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.route_rounded,
                        label: 'Total Routes',
                        value: totalRoutes.toString(),
                        color: AppColors.primary,
                      ),
                      _buildDivider(),
                      _StatRow(
                        icon: Icons.straighten_rounded,
                        label: 'Total Distance',
                        value: PathCalculator.formatDistance(totalDistance),
                        color: AppColors.accent,
                      ),
                      _buildDivider(),
                      _StatRow(
                        icon: Icons.directions_walk_rounded,
                        label: 'Total Steps',
                        value: totalSteps > 999
                            ? '${(totalSteps / 1000).toStringAsFixed(1)}k'
                            : totalSteps.toString(),
                        color: AppColors.success,
                      ),
                      _buildDivider(),
                      _StatRow(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Calories Burned',
                        value: PathCalculator.formatCalories(totalCalories),
                        color: AppColors.accentSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Achievements
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    Expanded(
                      child: _AchievementCard(
                        emoji: '🌱',
                        title: 'First Steps',
                        subtitle: 'Create your first route',
                        isUnlocked: totalRoutes > 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementCard(
                        emoji: '🗺️',
                        title: 'Explorer',
                        subtitle: '5 routes created',
                        isUnlocked: totalRoutes >= 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: _AchievementCard(
                        emoji: '🏃',
                        title: 'Marathon',
                        subtitle: '42km total distance',
                        isUnlocked: totalDistance >= 42000,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementCard(
                        emoji: '🔥',
                        title: 'Calorie Crusher',
                        subtitle: '1000 calories burned',
                        isUnlocked: totalCalories >= 1000,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Preferences
              FadeInUp(
                delay: const Duration(milliseconds: 650),
                child: Text(
                  'PREFERENCES',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Vibe',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Automatically updates maps and UI colors.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ThemeListItem(
                              title: 'Default Dark',
                              subtitle: 'Classic deep blue aesthetics',
                              type: AppThemeType.defaultDark,
                              color1: const Color(0xFF6C63FF),
                              color2: const Color(0xFF00E5FF),
                            ),
                            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                            _ThemeListItem(
                              title: 'Midnight',
                              subtitle: 'Cool tones for night owls',
                              type: AppThemeType.midnight,
                              color1: const Color(0xFF2196F3),
                              color2: const Color(0xFF00BCD4),
                            ),
                            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                            _ThemeListItem(
                              title: 'Neon Glow',
                              subtitle: 'Vibrant and energetic',
                              type: AppThemeType.neon,
                              color1: const Color(0xFFFF007F),
                              color2: const Color(0xFF00FFCC),
                            ),
                            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                            AnimatedBuilder(
                              animation: themeProvider,
                              builder: (context, _) {
                                final customMain = themeProvider.customColor;
                                final customAccent = HSLColor.fromColor(customMain)
                                    .withHue((HSLColor.fromColor(customMain).hue + 45) % 360)
                                    .withLightness(0.65)
                                    .toColor();
                                return _ThemeListItem(
                                  title: 'Custom Palette',
                                  subtitle: 'Tap to pick your own color',
                                  type: AppThemeType.custom,
                                  color1: customMain,
                                  color2: customAccent,
                                  onTapOverride: () {
                                    _showColorPicker(context);
                                  },
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Feedback & Contact
              FadeInUp(
                delay: const Duration(milliseconds: 750),
                child: Text(
                  'CONTACT & FEEDBACK',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeInUp(
                delay: const Duration(milliseconds: 780),
                child: Text(
                  'Have an idea for a new feature? Please suggest it here!',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactRow(
                        icon: Icons.email_rounded,
                        title: 'Email Support',
                        value: 'nilakantha.pradhan2801@gmail.com',
                      ),
                      _buildDivider(),
                      _ContactRow(
                        icon: Icons.phone_rounded,
                        title: 'Call Us',
                        value: '9337144828',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // App info
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Center(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'viA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: AppColors.primary, // More visible color
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your journey, visualized.',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8), // Better contrast
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final colors = [
      const Color(0xFF6C63FF), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF007F), // Neon Pink
      const Color(0xFFFF3D00), // Orange
      const Color(0xFF00E676), // Green
      const Color(0xFFFFD600), // Yellow
      const Color(0xFFD500F9), // Purple accent
      const Color(0xFF1DE9B6), // Teal
      const Color(0xFFF50057), // Rose
      const Color(0xFF3D5AFE), // Indigo
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Custom Color',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: colors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      themeProvider.setCustomColor(c);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isUnlocked;

  const _AchievementCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.bgDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isUnlocked)
                Pulse(
                  infinite: true,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)
                      ]
                    ),
                  ),
                ),
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 34,
                ),
              ),
              if (!isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.bgDark.withValues(alpha: 0.8), shape: BoxShape.circle),
                    child: Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: isUnlocked ? 0.9 : 0.5),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppThemeType type;
  final Color color1;
  final Color color2;
  final VoidCallback? onTapOverride;

  const _ThemeListItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color1,
    required this.color2,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        final isSelected = themeProvider.currentTheme == type;
        return InkWell(
          onTap: onTapOverride ?? () {
            themeProvider.setTheme(type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color1.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color1, color2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: color1.withValues(alpha: 0.4), blurRadius: 10)
                    ] : [],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? color1 : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color1, size: 24)
                else if (type == AppThemeType.custom)
                  Icon(Icons.color_lens_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 24)
              ],
            ),
          ),
        );
      }
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value, 
                  style: TextStyle(
                    color: AppColors.textPrimary, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600,
                  )
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied to clipboard'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}
