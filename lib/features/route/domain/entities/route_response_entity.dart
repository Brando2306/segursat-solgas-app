class RouteEntity {
  final int id;
  final int unitId;
  final String unitName;
  final String status;

  RouteEntity({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitid': unitId,
      'unit_name': unitName,
      'route_status': status,
    };
  }

  factory RouteEntity.fromJson(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'],
      unitId: json['unitid'],
      unitName: json['unit_name'],
      status: json['route_status'],
    );
  }
}
