class RouteEntity {
  final int id;
  final String unitName;
  final String status;
  final DateTime timestamp;

  RouteEntity({
    required this.id,
    required this.unitName,
    required this.status,
    required this.timestamp,
  });

  factory RouteEntity.fromJson(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'],
      unitName: json['unitName'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unitName': unitName,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  RouteEntity copyWith({
    int? id,
    String? unitName,
    String? status,
    DateTime? timestamp,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      unitName: unitName ?? this.unitName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
