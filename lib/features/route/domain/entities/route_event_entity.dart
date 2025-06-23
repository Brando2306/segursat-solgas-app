class EmergencyEventEntity {
  final dynamic routeId;
  final dynamic unitId;
  final dynamic timestamp;
  final dynamic latitude;
  final dynamic longitude;

  EmergencyEventEntity({
    required this.routeId,
    required this.unitId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeid': routeId,
      'unitid': unitId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EmergencyEventEntity.fromJson(Map<String, dynamic> json) {
    return EmergencyEventEntity(
      routeId: json['routeid'],
      unitId: json['unitid'],
      timestamp: json['timestamp'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
