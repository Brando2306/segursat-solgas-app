import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';

abstract class OfflineOperationsRepository {
  Future<void> saveOperation(OfflineOperation operation);
  Future<List<OfflineOperation>> getPendingOperations();
  Future<void> removeOperation(String id);
  Future<bool> hasPendingRouteOperation();
  Future<void> retryOperation(String id);
}
