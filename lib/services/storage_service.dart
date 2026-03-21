import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:via_app/models/route_record.dart';
import 'package:via_app/utils/distance_calculator.dart';

class StorageService {
  static const String _routesBoxName = 'routes';
  static const String _prefsBoxName = 'prefs';
  static late Box<RouteRecord> _routesBox;
  static late Box _prefsBox;
  static const _uuid = Uuid();

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(RouteRecordAdapter());
    _routesBox = await Hive.openBox<RouteRecord>(_routesBoxName);
    _prefsBox = await Hive.openBox(_prefsBoxName);
  }

  // ============ PREFERENCES ============

  /// Check if welcome screen has been shown before
  static bool hasSeenWelcome() {
    return _prefsBox.get('welcome_seen', defaultValue: false) as bool;
  }

  /// Mark welcome screen as shown
  static Future<void> markWelcomeShown() async {
    await _prefsBox.put('welcome_seen', true);
  }

  /// Check if hint has been dismissed
  static bool hasClosedHint() {
    return _prefsBox.get('hint_closed', defaultValue: false) as bool;
  }

  /// Mark hint as dismissed
  static Future<void> markHintClosed() async {
    await _prefsBox.put('hint_closed', true);
  }

  // ============ ROUTES ============

  /// Save a new route
  static Future<RouteRecord> saveRoute({
    required String name,
    required List<LatLng> points,
    required double distanceMeters,
    required int steps,
    required double calories,
    required double durationMinutes,
  }) async {
    final record = RouteRecord(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      latitudes: points.map((p) => p.latitude).toList(),
      longitudes: points.map((p) => p.longitude).toList(),
      distanceMeters: distanceMeters,
      steps: steps,
      calories: calories,
      durationMinutes: durationMinutes,
    );

    await _routesBox.put(record.id, record);
    return record;
  }

  /// Get all saved routes sorted by date (newest first)
  static List<RouteRecord> getRoutes() {
    final routes = _routesBox.values.toList();
    routes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return routes;
  }

  /// Get a single route by ID
  static RouteRecord? getRoute(String id) {
    return _routesBox.get(id);
  }

  /// Delete a route by ID
  static Future<void> deleteRoute(String id) async {
    await _routesBox.delete(id);
  }

  /// Get LatLng points from a RouteRecord
  static List<LatLng> getRoutePoints(RouteRecord record) {
    final points = <LatLng>[];
    for (int i = 0; i < record.latitudes.length; i++) {
      points.add(LatLng(record.latitudes[i], record.longitudes[i]));
    }
    return points;
  }

  /// Get aggregate statistics
  static Map<String, dynamic> getStats() {
    final routes = getRoutes();
    double totalDistance = 0;
    int totalSteps = 0;
    double totalCalories = 0;

    for (final route in routes) {
      totalDistance += route.distanceMeters;
      totalSteps += route.steps;
      totalCalories += route.calories;
    }

    return {
      'totalRoutes': routes.length,
      'totalDistance': totalDistance,
      'totalDistanceFormatted': PathCalculator.formatDistance(totalDistance),
      'totalSteps': totalSteps,
      'totalCalories': totalCalories,
    };
  }
}
