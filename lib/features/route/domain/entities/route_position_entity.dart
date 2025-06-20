class RoutePositionEntity {
  final dynamic routeId;
  final dynamic unitId;
  final dynamic timestamp;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic altitude;
  final dynamic speed;
  final dynamic angle;

  RoutePositionEntity({
    required this.routeId,
    required this.unitId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.angle,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeid': routeId,
      'unitid': unitId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'angle': angle,
    };
  }

  factory RoutePositionEntity.fromJson(Map<String, dynamic> json) {
    return RoutePositionEntity(
      routeId: json['routeid'],
      unitId: json['unitid'],
      timestamp: json['timestamp'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      speed: json['speed'],
      angle: json['angle'],
    );
  }

  RoutePositionEntity copyWith({
    dynamic routeId,
    dynamic unitId,
    dynamic timestamp,
    dynamic latitude,
    dynamic longitude,
    dynamic altitude,
    dynamic speed,
    dynamic angle,
  }) {
    return RoutePositionEntity(
      routeId: routeId ?? this.routeId,
      unitId: unitId ?? this.unitId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      angle: angle ?? this.angle,
    );
  }
}
