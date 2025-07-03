import 'dart:convert';

class StopRouteEntity {
  final dynamic routeId;
  final dynamic unitId;
  final dynamic timestamp;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic type;
  final dynamic description;
  final dynamic address;
  final dynamic time;
  final List<Map<String, dynamic>> questions;

  StopRouteEntity({
    required this.routeId,
    required this.unitId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.description,
    required this.address,
    required this.time,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'routeid': routeId,
        'unitid': unitId,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
        'description': description,
        'address': address,
        'time': time,
        'questions': json.encode(questions),
      };

  factory StopRouteEntity.fromJson(Map<String, dynamic> json) {
    return StopRouteEntity(
      routeId: json['routeid'],
      unitId: json['unitid'],
      timestamp: json['timestamp'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      type: json['type'],
      description: json['description'],
      address: json['address'],
      time: json['time'],
      questions: List<Map<String, dynamic>>.from(
          jsonDecode(json['questions'] ?? '[]')),
    );
  }

  StopRouteEntity copyWith({
    dynamic routeId,
    dynamic unitId,
    dynamic timestamp,
    dynamic latitude,
    dynamic longitude,
    dynamic type,
    dynamic description,
    dynamic address,
    dynamic time,
    List<Map<String, dynamic>>? questions,
  }) {
    return StopRouteEntity(
      routeId: routeId ?? this.routeId,
      unitId: unitId ?? this.unitId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      description: description ?? this.description,
      address: address ?? this.address,
      time: time ?? this.time,
      questions: questions ?? this.questions,
    );
  }
}
