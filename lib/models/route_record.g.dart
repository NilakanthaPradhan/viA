// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RouteRecordAdapter extends TypeAdapter<RouteRecord> {
  @override
  final int typeId = 0;

  @override
  RouteRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return RouteRecord(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      latitudes: (fields[3] as List).cast<double>(),
      longitudes: (fields[4] as List).cast<double>(),
      distanceMeters: fields[5] as double,
      steps: fields[6] as int,
      calories: fields[7] as double,
      durationMinutes: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RouteRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.latitudes)
      ..writeByte(4)
      ..write(obj.longitudes)
      ..writeByte(5)
      ..write(obj.distanceMeters)
      ..writeByte(6)
      ..write(obj.steps)
      ..writeByte(7)
      ..write(obj.calories)
      ..writeByte(8)
      ..write(obj.durationMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
