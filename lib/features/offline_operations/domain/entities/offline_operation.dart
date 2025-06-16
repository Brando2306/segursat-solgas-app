import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/route/domain/entities/route.dart';

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final int retryCount;
  final String? lastError;

  OfflineOperation({
    required this.type,
    required this.data,
    String? id,
    this.lastError,
    this.retryCount = 0,
    DateTime? createdAt,
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
        orElse: () => OfflineOperationType.routeRecovery,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      data: dataField,
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
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
}
