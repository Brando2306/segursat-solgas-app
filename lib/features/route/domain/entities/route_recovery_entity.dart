class RouteRecoveryEntity {
  final String id;
  final int routeId;
  final DateTime timestamp;
  final Map<String, dynamic> routeData;

  RouteRecoveryEntity({
    String? id,
    required this.routeId,
    required this.timestamp,
    required this.routeData,
  }) : id = id ?? 'route_rec_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'timestamp': timestamp.toIso8601String(),
      'routeData': routeData,
    };
  }

  factory RouteRecoveryEntity.fromJson(Map<String, dynamic> json) {
    return RouteRecoveryEntity(
      id: json['id'],
      routeId: json['routeId'],
      timestamp: DateTime.parse(json['timestamp']),
      routeData: json['routeData'],
    );
  }
}
