class IncidentRouteEntity {
  final dynamic routeId;
  final dynamic timestamp;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic type;
  final dynamic description;
  final dynamic address;
  final dynamic unitId;

  IncidentRouteEntity({
    required this.routeId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    required this.address,
    required this.unitId,
  });

  Map<String, dynamic> toJson() => {
        "routeid": routeId,
        "timestamp": timestamp,
        "latitude": latitude,
        "longitude": longitude,
        "type": type,
        "description": description,
        "address": address,
        "unitid": unitId,
      };

  factory IncidentRouteEntity.fromJson(Map<String, dynamic> json) {
    return IncidentRouteEntity(
      routeId: json['routeid'],
      timestamp: json['timestamp'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      type: json['type'],
      description: json['description'],
      address: json['address'],
      unitId: json['unitid'],
    );
  }

  IncidentRouteEntity copyWith({
    dynamic routeId,
    dynamic timestamp,
    dynamic latitude,
    dynamic longitude,
    dynamic type,
    dynamic description,
    dynamic address,
    dynamic unitId,
  }) {
    return IncidentRouteEntity(
      routeId: routeId ?? this.routeId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      description: description ?? this.description,
      address: address ?? this.address,
      unitId: unitId ?? this.unitId,
    );
  }
}
