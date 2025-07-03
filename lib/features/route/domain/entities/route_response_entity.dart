class RouteEntity {
  final int id;
  final List<PositionEntity> positions;
  final int unitId;
  final String unitName;
  final double sourceLatitude;
  final double sourceLongitude;
  final String sourceAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationAddress;
  final String status;

  RouteEntity({
    required this.id,
    required this.positions,
    required this.unitId,
    required this.unitName,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.sourceAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationAddress,
    required this.status,
  });

  factory RouteEntity.fromJson(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'],
      positions: (json['positions'] as List)
          .map((e) => PositionEntity.fromJson(e))
          .toList(),
      unitId: json['unitid'],
      unitName: json['unit_name'],
      sourceLatitude: (json['source_latitude'] as num).toDouble(),
      sourceLongitude: (json['source_longitude'] as num).toDouble(),
      sourceAddress: json['source_address'],
      destinationLatitude: (json['destination_latitude'] as num).toDouble(),
      destinationLongitude: (json['destination_longitude'] as num).toDouble(),
      destinationAddress: json['destination_address'],
      status: json['route_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'positions': positions.map((e) => e.toJson()).toList(),
      'unitid': unitId,
      'unit_name': unitName,
      'source_latitude': sourceLatitude,
      'source_longitude': sourceLongitude,
      'source_address': sourceAddress,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'destination_address': destinationAddress,
      'route_status': status,
    };
  }
}

class PositionEntity {
  final int id;
  final int unitId;
  final String unitName;
  final int timestamp;
  final double latitude;
  final double longitude;
  final int altitude;
  final int speed;
  final int angle;

  PositionEntity({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.angle,
  });

  factory PositionEntity.fromJson(Map<String, dynamic> json) {
    return PositionEntity(
      id: json['id'],
      unitId: json['unitid'],
      unitName: json['unit_name'],
      timestamp: json['timestamp'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'],
      speed: json['speed'],
      angle: json['angle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitid': unitId,
      'unit_name': unitName,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'angle': angle,
    };
  }
}
