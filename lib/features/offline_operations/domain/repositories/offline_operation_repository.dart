import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';

abstract class OfflineOperationsRepository {
  Future<void> saveOperation(OfflineOperation operation);
  Future<List<OfflineOperation>> getPendingOperations();
  Future<List<OfflineOperation>> getOperationsByType(OfflineOperationType type);
  Future<void> removeOperation(String id);
  Future<bool> hasPendingRouteOperation();
  Future<void> retryOperation(String id);
  Future<OfflineOperation?> getOperationById(String id);
  Future<void> updateRetryCount(String id, int retryCount, String? lastError);

  // Métodos específicos para tipos de operaciones
  Future<List<OfflineOperation>> getRouteRecoveryOperations();
  Future<List<OfflineOperation>> getMaintenanceOperations();
  Future<List<OfflineOperation>> getRoutePositionsOperations();

  Future<OfflineOperation?> getMaintenanceOperationByUniqueKey(String routeId);
  Future<OfflineOperation?> getInspectionOperationByUniqueKey(
      String inspectionId);

  // Operaciones básicas
  Future<List<OfflineOperation>> getOperationsByRoute(String routeId);
  Future<void> updateOperation(OfflineOperation operation);

  // Operaciones específicas de ruta
  Future<void> saveFailedRouteCreation(
      CreateRouteEntity route, String offlineRouteId);
  Future<void> saveFailedPositions(
      List<RoutePositionEntity> positions, String offlineRouteId);
  Future<void> saveFailedRouteFinish(
      FinishRouteEntity route, String offlineRouteId);

  // Métodos para reintentar
  Future<void> retryRouteCreation(String operationId);
  Future<void> retryRoutePositions(String operationId);
  Future<void> retryRouteFinish(String operationId);

  // Agrupación de operaciones
  Future<Map<String, List<OfflineOperation>>> getGroupedRouteOperations();
}
