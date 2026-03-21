import 'package:hive/hive.dart';

part 'route_record.g.dart';

@HiveType(typeId: 0)
class RouteRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<double> latitudes;

  @HiveField(4)
  final List<double> longitudes;

  @HiveField(5)
  final double distanceMeters;

  @HiveField(6)
  final int steps;

  @HiveField(7)
  final double calories;

  @HiveField(8)
  final double durationMinutes;

  RouteRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.latitudes,
    required this.longitudes,
    required this.distanceMeters,
    required this.steps,
    required this.calories,
    required this.durationMinutes,
  });
}
