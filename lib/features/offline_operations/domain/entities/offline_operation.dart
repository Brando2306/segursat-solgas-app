import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/route/domain/entities/route.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> data;
  final int retryCount;
  final String? lastError;
  final String? routeId; // Para agrupar operaciones por ruta
  final String? offlineRouteId;

  OfflineOperation({
    required this.type,
    required this.data,
    String? id,
    this.lastError,
    this.retryCount = 0,
    DateTime? createdAt,
    this.updatedAt,
    this.routeId,
    this.offlineRouteId,
  })  : id = id == null || id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : id,
        createdAt = createdAt ?? DateTime.now();

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataField;
    if (json['data'] is String) {
      dataField = jsonDecode(json['data']);
    } else if (json['data'] is Map) {
      dataField = Map<String, dynamic>.from(json['data']);
    } else {
      dataField = {};
    }

    return OfflineOperation(
      id: json['id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => OfflineOperationType.routeCreation,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      data: dataField,
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
      routeId: json['routeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'data': jsonEncode(data),
      'retryCount': retryCount,
      'lastError': lastError,
      'routeId': routeId,
    };
  }

  OfflineOperation copyWith({
    String? id,
    OfflineOperationType? type,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    int? retryCount,
    String? lastError,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  // Métodos para crear diferentes tipos de operaciones
  static OfflineOperation routeCreation(
      CreateRouteEntity route, String offlineRouteId) {
    return OfflineOperation(
      id: 'route_${route.unitName}_${DateTime.now().millisecondsSinceEpoch}',
      type: OfflineOperationType.routeCreation,
      data: route.toJson(),
      offlineRouteId: offlineRouteId,
    );
  }

  static OfflineOperation routePositions(
      List<RoutePositionEntity> positions, String offlineRouteId) {
    return OfflineOperation(
      type: OfflineOperationType.routePositions,
      data: {'positions': positions.map((p) => p.toJson()).toList()},
      // data: {
      //   'positions': positions.map((p) => p.toJson()).toList(),
      //   'routeId': positions.isNotEmpty ? positions.first.routeId : null,
      // },
      offlineRouteId: offlineRouteId,
    );
  }

  static OfflineOperation routeFinish(
      FinishRouteEntity route, String offlineRouteId) {
    return OfflineOperation(
      type: OfflineOperationType.routeFinish,
      data: route.toJson(),
      offlineRouteId: offlineRouteId,
    );
  }

  // Método para obtener el ID de ruta asociado (si existe)
  String? get associatedRouteId {
    switch (type) {
      case OfflineOperationType.routeCreation:
        return data['unit_name'] ?? data['unitName'];
      case OfflineOperationType.routePositions:
        return data['routeId'] ?? (data['positions']?.first['routeid']);
      case OfflineOperationType.routeFinish:
      case OfflineOperationType.routeCancel:
        return data['routeid'] ?? data['routeId'];
      default:
        return null;
    }
  }
}
