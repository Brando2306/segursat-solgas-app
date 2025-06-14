class RouteEventEntity {
  final dynamic routeId;
  final dynamic unitId;
  final dynamic timestamp;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic eventType;

  RouteEventEntity({
    required this.routeId,
    required this.unitId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.eventType,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeid': routeId,
      'unitid': unitId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'eventType': eventType,
    };
  }

  factory RouteEventEntity.fromJson(Map<String, dynamic> json) {
    return RouteEventEntity(
      routeId: json['routeid'],
      unitId: json['unitid'],
      timestamp: json['timestamp'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      eventType: json['eventType'],
    );
  }
}
