enum RouteStatus { pending, running, completed, cancelled }

class Position {
  final double latitude;
  final double longitude;

  Position({required this.latitude, required this.longitude});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  Position copyWith({
    double? latitude,
    double? longitude,
  }) {
    return Position(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class RoutePosition {
  final String id;
  final int routeId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final int angle;

  RoutePosition({
    required this.routeId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.angle,
    String? id,
  }) : id = (id == null || id.isEmpty)
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : id;

  factory RoutePosition.fromJson(Map<String, dynamic> json) {
    return RoutePosition(
      id: json['id'],
      routeId: json['routeId'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble() ?? 0.0,
      speed: json['speed']?.toDouble() ?? 0.0,
      angle: json['angle'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'angle': angle,
      };

  RoutePosition copyWith({
    String? id,
    int? routeId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    int? angle,
  }) {
    return RoutePosition(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      angle: angle ?? this.angle,
    );
  }
}

class Route {
  final int id;
  final String unitName;
  final RouteStatus status;
  final DateTime timestamp;
  final Position source;
  final Position destination;
  final List<RoutePosition>? positions;

  Route({
    required this.id,
    required this.unitName,
    required this.status,
    required this.timestamp,
    required this.source,
    required this.destination,
    this.positions,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'],
      unitName: json['unitName'],
      status: RouteStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RouteStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      source: Position.fromJson(json['source']),
      destination: Position.fromJson(json['destination']),
      positions: json['positions'] != null
          ? (json['positions'] as List)
              .map((e) => RoutePosition.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unitName': unitName,
        'status': status.toString().split('.').last,
        'timestamp': timestamp.toIso8601String(),
        'source': source.toJson(),
        'destination': destination.toJson(),
        'positions': positions?.map((e) => e.toJson()).toList(),
      };

  Route copyWith({
    int? id,
    String? unitName,
    RouteStatus? status,
    DateTime? timestamp,
    Position? source,
    Position? destination,
    List<RoutePosition>? positions,
  }) {
    return Route(
      id: id ?? this.id,
      unitName: unitName ?? this.unitName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      positions: positions ?? this.positions,
    );
  }
}
