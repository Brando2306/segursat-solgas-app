import 'dart:convert';

class RouteEntity {
  final int id;
  final String unitName;
  final String status;

  RouteEntity({
    required this.id,
    required this.unitName,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitName': unitName,
      'status': status,
    };
  }

  factory RouteEntity.fromJson(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'],
      unitName: json['unitName'],
      status: json['status'],
    );
  }
}
