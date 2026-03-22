import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/utils/distance_calculator.dart';

class StatsPanel extends StatelessWidget {
  final double distance;
  final int steps;
  final double calories;
  final double duration;
  final int pointCount;
  final double? currentSpeed;

  const StatsPanel({
    super.key,
    required this.distance,
    required this.steps,
    required this.calories,
    required this.duration,
    required this.pointCount,
    this.currentSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Icon(Icons.analytics_rounded,
                        size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Path Statistics',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (currentSpeed != null && currentSpeed! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${currentSpeed!.toStringAsFixed(1)} km/h',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pointCount pts',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.straighten_rounded,
                      value: PathCalculator.formatDistance(distance),
                      label: 'Distance',
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_walk_rounded,
                      value: steps > 999
                          ? '${(steps / 1000).toStringAsFixed(1)}k'
                          : steps.toString(),
                      label: 'Steps',
                      gradient: LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: PathCalculator.formatCalories(calories),
                      label: 'Calories',
                      gradient: AppColors.accentGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_rounded,
                      value: PathCalculator.formatDuration(duration),
                      label: 'Est. Time',
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFAB40), Color(0xFFFFD740)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
