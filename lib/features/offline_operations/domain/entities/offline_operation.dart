import 'dart:convert';

import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> data;
  final int retryCount;
  final String? lastError;
  final String? routeId;
  final String? offlineRouteId;
  final bool synced;

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
    this.synced = false,
  })  : id = id == null || id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : id,
        createdAt = createdAt ?? DateTime.now();

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    // Manejo del campo 'synced' (puede venir como int o bool)
    final synced = json['synced'] is int
        ? json['synced'] == 1
        : json['synced'] as bool? ?? false;

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
      offlineRouteId: json['offlineRouteId'],
      synced: synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'data': jsonEncode(data),
      'retryCount': retryCount,
      'lastError': lastError,
      'routeId': routeId,
      'offlineRouteId': offlineRouteId,
      'synced': synced ? 1 : 0,
    };
  }

  OfflineOperation copyWith({
    String? id,
    OfflineOperationType? type,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    int? retryCount,
    String? lastError,
    String? offlineRouteId,
    String? routeId,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      offlineRouteId: offlineRouteId ?? this.offlineRouteId,
      routeId: routeId ?? this.routeId,
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

  static OfflineOperation routeCancel(
      CancelRouteEntity route, String offlineRouteId) {
    return OfflineOperation(
      type: OfflineOperationType.routeCancel,
      data: route.toJson(),
      offlineRouteId: offlineRouteId,
    );
  }

  static OfflineOperation incidentReport(
      IncidentRouteEntity incident, String offlineRouteId) {
    return OfflineOperation(
      type: OfflineOperationType.incidentReport,
      data: incident.toJson(),
      offlineRouteId: offlineRouteId,
    );
  }
}
