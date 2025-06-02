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
    final operation = await _getOperationById(id);
    if (operation == null) return;

    try {
      // Aquí iría la lógica para reintentar la operación
      // Dependiendo del tipo de operación
      await _handleOperationRetry(operation);

      // Si tiene éxito, eliminar de la base de datos
      await removeOperation(id);
    } catch (e) {
      // Si falla, actualizar conteo de reintentos
      await database.update(
        tableName,
        {
          'retryCount': operation.retryCount + 1,
          'lastError': e.toString(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
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
}
