import 'dart:convert';

import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:sqflite/sqflite.dart';

class OfflineOperationsRepositoryImpl implements OfflineOperationsRepository {
  final Database database;
  static const String tableName = 'offline_operations';

  OfflineOperationsRepositoryImpl({required this.database}) {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        data TEXT NOT NULL,
        retryCount INTEGER NOT NULL,
        lastError TEXT
      )
    ''');
  }

  @override
  Future<void> saveOperation(OfflineOperation operation) async {
    await database.insert(
      tableName,
      operation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<OfflineOperation>> getPendingOperations() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return maps.map((map) => OfflineOperation.fromJson(map)).toList();
  }

  @override
  Future<List<OfflineOperation>> getOperationsByType(
      OfflineOperationType type) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'type = ?',
      whereArgs: [type.toString()],
    );
    return maps.map((map) => OfflineOperation.fromJson(map)).toList();
  }

  @override
  Future<void> removeOperation(String id) async {
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> hasPendingRouteOperation() async {
    final count = Sqflite.firstIntValue(await database.rawQuery(
      '''
      SELECT COUNT(*) FROM $tableName 
      WHERE type = ? AND lastError IS NULL
      ''',
      [OfflineOperationType.routeRecovery.toString()],
    ));
    return count != null && count > 0;
  }

  @override
  Future<void> retryOperation(String id) async {
    final operation = await getOperationById(id);
    if (operation == null) return;

    try {
      // Lógica para reintentar la operación según el tipo
      // Esto debería implementarse en el provider correspondiente
      await updateRetryCount(id, operation.retryCount + 1, 'Reintentando...');
    } catch (e) {
      await updateRetryCount(id, operation.retryCount + 1, e.toString());
      rethrow;
    }
  }

  @override
  Future<OfflineOperation?> getOperationById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OfflineOperation.fromJson(maps.first);
  }

  @override
  Future<void> updateRetryCount(
      String id, int retryCount, String? lastError) async {
    await database.update(
      tableName,
      {
        'retryCount': retryCount,
        'lastError': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<OfflineOperation>> getRouteRecoveryOperations() async {
    return getOperationsByType(OfflineOperationType.routeRecovery);
  }

  @override
  Future<List<OfflineOperation>> getMaintenanceOperations() async {
    return getOperationsByType(OfflineOperationType.maintenance);
  }

  @override
  Future<List<OfflineOperation>> getRoutePositionsOperations() async {
    return getOperationsByType(OfflineOperationType.routePositions);
  }

  @override
  Future<List<OfflineOperation>> getRouteEventOperations() async {
    return getOperationsByType(OfflineOperationType.routeEvent);
  }

  Future<void> _handleOperationRetry(OfflineOperation operation) async {
    switch (operation.type) {
      case OfflineOperationType.routeRecovery:
        // Lógica específica para recuperación de ruta
        break;
      case OfflineOperationType.maintenance:
        // Lógica para mantenimiento
        break;
      case OfflineOperationType.inspection:
        // Lógica para inspección
        break;
      case OfflineOperationType.incidentReport:
        // Lógica para reporte de incidente
        break;
    }
  }

  @override
  Future<void> saveRouteCreationAttempt(
      int routeId, Map<String, dynamic> data) async {
    final operation = OfflineOperation(
      type: OfflineOperationType.routeCreation,
      data: {
        'routeId': routeId,
        'action': 'create',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await saveOperation(operation);
  }

  @override
  Future<void> saveMaintenanceAttempt(Map<String, dynamic> formData) async {
    final operation = OfflineOperation(
      type: OfflineOperationType.maintenance,
      data: {
        'action': 'submit',
        'data': formData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await saveOperation(operation);
  }

  @override
  Future<void> saveRoutePositionBatch(
      List<Map<String, dynamic>> positions) async {
    final operation = OfflineOperation(
      type: OfflineOperationType.routePositions,
      data: {
        'action': 'batch_insert',
        'positions': positions,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await saveOperation(operation);
  }

  @override
  Future<void> saveRouteEvent(
      String routeId, String eventType, Map<String, dynamic> data) async {
    final operation = OfflineOperation(
      type: OfflineOperationType.routeEvent,
      data: {
        'routeId': routeId,
        'eventType': eventType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await saveOperation(operation);
  }

  @override
  Future<OfflineOperation?> getMaintenanceOperationByUniqueKey(
      String maintenanceId) async {
    // Obtener todas las operaciones de mantenimiento
    final List<Map<String, dynamic>> allMaps = await database.query(
      tableName,
      where: "type = ?",
      whereArgs: [OfflineOperationType.maintenance.toString()],
    );

    // Filtrar localmente
    for (final map in allMaps) {
      try {
        final dataJson = jsonDecode(map['data'] as String);
        if (dataJson['id'] == maintenanceId) {
          return OfflineOperation.fromJson(map);
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<OfflineOperation?> getInspectionOperationByUniqueKey(
      String inspectionId) async {
    final List<Map<String, dynamic>> allMaps = await database.query(
      tableName,
      where: "type = ?",
      whereArgs: [OfflineOperationType.inspection.toString()],
    );

    for (final map in allMaps) {
      try {
        final dataJson = jsonDecode(map['data'] as String);
        if (dataJson['id'] == inspectionId) {
          return OfflineOperation.fromJson(map);
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<List<OfflineOperation>> getInspectionOperations() async {
    return getOperationsByType(OfflineOperationType.inspection);
  }
}
