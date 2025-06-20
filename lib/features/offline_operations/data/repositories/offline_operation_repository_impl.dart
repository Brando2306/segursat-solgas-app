import 'dart:convert';
import 'dart:developer';

import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
import 'package:sqflite/sqflite.dart';

class OfflineOperationsRepositoryImpl implements OfflineOperationsRepository {
  final Database database;
  static const String tableName = 'offline_operations';

  OfflineOperationsRepositoryImpl({required this.database});

  @override
  Future<void> saveOperation(OfflineOperation operation) async {
    log('[DEBUG] Guardando operación offline: ${operation.type} offlineRouteId=${operation.offlineRouteId}');
    await database.insert(
      tableName,
      operation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveFailedRouteCreation(
      CreateRouteEntity route, String offlineRouteId) async {
    final operation = OfflineOperation.routeCreation(route, offlineRouteId);
    await saveOperation(operation);
  }

  @override
  Future<void> saveFailedPositions(
      List<RoutePositionEntity> positions, String offlineRouteId) async {
    if (positions.isEmpty) return;

    // 1. Buscar si ya existe una operación de posiciones para esta ruta
    final existingOps = await getOperationsByOfflineId(offlineRouteId);
    final existingPositionsOp = existingOps.firstWhere(
      (op) => op.type == OfflineOperationType.routePositions,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routePositions,
        data: {'positions': []},
        offlineRouteId: offlineRouteId,
      ),
    );

    // 2. Fusionar las nuevas posiciones con las existentes
    final List<Map<String, dynamic>> allPositions = [
      ...(existingPositionsOp.data['positions'] as List? ?? []),
      ...positions.map((p) => p.toJson()).toList(),
    ];

    // 3. Actualizar o crear la operación consolidada
    final updatedOp = existingPositionsOp.copyWith(
      data: {'positions': allPositions},
    );

    await saveOperation(updatedOp);
  }

  @override
  Future<void> saveFailedRouteFinish(
      FinishRouteEntity route, String offlineRouteId) async {
    final operation = OfflineOperation.routeFinish(route, offlineRouteId);
    await saveOperation(operation);
  }

  @override
  Future<Map<String, List<OfflineOperation>>>
      getGroupedRouteOperations() async {
    final operations = await database.query('offline_operations');
    final offlineOps =
        operations.map((e) => OfflineOperation.fromJson(e)).toList();

    final grouped = <String, List<OfflineOperation>>{};

    for (final op in offlineOps.where((o) => o.offlineRouteId != null)) {
      grouped.putIfAbsent(op.offlineRouteId!, () => []).add(op);
    }

    return grouped;
  }

  // @override
  // Future<Map<String, List<OfflineOperation>>>
  //     getGroupedRouteOperations() async {
  //   final operations = await getPendingOperations();
  //   final grouped = <String, List<OfflineOperation>>{};

  //   for (final op in operations.where((o) => o.offlineRouteId != null)) {
  //     grouped.putIfAbsent(op.offlineRouteId!, () => []).add(op);
  //   }

  //   return grouped;
  // }

  @override
  Future<List<OfflineOperation>> getPendingOperations() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return maps.map((map) => OfflineOperation.fromJson(map)).toList();
  }

  @override
  Future<List<OfflineOperation>> getOperationsByRoute(String routeId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'routeId = ?',
      whereArgs: [routeId],
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
  Future<void> updateOperation(OfflineOperation operation) async {
    await database.update(
      tableName,
      operation.toJson(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  @override
  Future<void> retryRouteCreation(String operationId) async {
    final operation = await _getOperationById(operationId);
    if (operation == null ||
        operation.type != OfflineOperationType.routeCreation) {
      return;
    }

    try {
      // Aquí deberías implementar la lógica para reintentar la creación
      // Por ejemplo, llamar al RouteRepository para crear la ruta
      // Si tiene éxito:
      await removeOperation(operationId);
    } catch (e) {
      await _updateOperationError(operationId, e.toString());
      rethrow;
    }
  }

  @override
  Future<void> retryRoutePositions(String operationId) async {
    final operation = await _getOperationById(operationId);
    if (operation == null ||
        operation.type != OfflineOperationType.routePositions) {
      return;
    }

    try {
      // Implementar lógica para reintentar envío de posiciones
      // Si tiene éxito:
      await removeOperation(operationId);
    } catch (e) {
      await _updateOperationError(operationId, e.toString());
      rethrow;
    }
  }

  @override
  Future<void> retryRouteFinish(String operationId) async {
    final operation = await _getOperationById(operationId);
    if (operation == null ||
        operation.type != OfflineOperationType.routeFinish) {
      return;
    }

    try {
      // Implementar lógica para reintentar finalización
      // Si tiene éxito:
      await removeOperation(operationId);
    } catch (e) {
      await _updateOperationError(operationId, e.toString());
      rethrow;
    }
  }

  Future<OfflineOperation?> _getOperationById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OfflineOperation.fromJson(maps.first);
  }

  Future<void> _updateOperationError(String id, String error) async {
    final operation = await _getOperationById(id);
    if (operation != null) {
      await database.update(
        tableName,
        {
          'retryCount': operation.retryCount + 1,
          'lastError': error,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
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
  Future<List<OfflineOperation>> getOperationsByOfflineId(
      String offlineId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'offlineRouteId = ?',
      whereArgs: [offlineId],
    );
    return maps.map((map) => OfflineOperation.fromJson(map)).toList();
  }

  @override
  Future<void> markOperationAsSynced(String id) async {
    await database.update(
      'offline_operations',
      {
        'synced': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<OfflineOperation>> getSyncedOperations(
      String offlineRouteId) async {
    final maps = await database.query(
      'offline_operations',
      where: 'offlineRouteId = ? AND synced = 1',
      whereArgs: [offlineRouteId],
    );
    return maps.map((map) => OfflineOperation.fromJson(map)).toList();
  }
}
