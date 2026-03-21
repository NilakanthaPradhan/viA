import 'package:flutter/material.dart';
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/services/storage_service.dart';
import 'package:via_app/utils/distance_calculator.dart';
import 'package:via_app/widgets/glass_container.dart';
import 'package:animate_do/animate_do.dart';

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
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                      const Text(
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
                child: const Text(
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
                child: const Text(
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
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your journey, visualized.',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
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
                    child: const Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
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
