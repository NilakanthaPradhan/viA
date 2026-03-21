import 'dart:math';
import 'package:latlong2/latlong.dart';

class PathCalculator {
  /// Average human step length in meters
  static const double avgStepLength = 0.762;

  /// Average calories per km walking
  static const double caloriesPerKm = 60.0;

  /// Calculate distance between two LatLng points using Haversine formula
  /// Returns distance in meters
  static double haversineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final double dLng = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate total distance along a path of LatLng points
  /// Returns distance in meters
  static double calculatePathDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += haversineDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Estimate number of steps for given distance in meters
  static int calculateSteps(double distanceInMeters) {
    return (distanceInMeters / avgStepLength).round();
  }

  /// Estimate calories burned for given distance in km
  static double calculateCalories(double distanceInKm) {
    return distanceInKm * caloriesPerKm;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Format steps with comma separator
  static String formatSteps(int steps) {
    if (steps < 1000) return steps.toString();
    return '${(steps / 1000).toStringAsFixed(1)}k';
  }

  /// Format calories
  static String formatCalories(double calories) {
    return '${calories.toStringAsFixed(0)} kcal';
  }

  /// Estimate walking duration in minutes
  static double estimateWalkingMinutes(double distanceInMeters) {
    // Average walking speed: ~5 km/h = ~83.33 m/min
    const double walkingSpeedMPerMin = 83.33;
    return distanceInMeters / walkingSpeedMPerMin;
  }

  /// Format duration
  static String formatDuration(double minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '${minutes.toStringAsFixed(0)} min';
    final int hours = (minutes / 60).floor();
    final int mins = (minutes % 60).round();
    return '${hours}h ${mins}m';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
