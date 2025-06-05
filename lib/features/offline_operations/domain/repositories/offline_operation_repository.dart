import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';

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
  Future<List<OfflineOperation>> getRouteEventOperations();

  Future<OfflineOperation?> getMaintenanceOperationByUniqueKey(String routeId);
  Future<OfflineOperation?> getInspectionOperationByUniqueKey(String inspectionId);

}
