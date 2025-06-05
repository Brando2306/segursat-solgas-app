import 'package:safe_driving_app/features/maintenance/data/datasources/maintenance_remote_datasource.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceRemoteDataSource remoteDataSource;
  final OfflineOperationsRepository offlineOperationsRepository;

  MaintenanceRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineOperationsRepository,
  });

  @override
  Future<void> submitMaintenance(
    MaintenanceEntity maintenance, {
    bool isRetry = false,
  }) async {
    try {
      await remoteDataSource.uploadMaintenance(maintenance);
    } catch (e) {
      // Solo maneja offline si NO es un reintento
      if (!isRetry) {
        final existingOperation = await offlineOperationsRepository
            .getMaintenanceOperationByUniqueKey(maintenance.id);
        if (existingOperation == null) {
          await offlineOperationsRepository.saveOperation(
            OfflineOperation(
              type: OfflineOperationType.maintenance,
              data: maintenance.toJson(),
            ),
          );
        } else {
          await offlineOperationsRepository.updateRetryCount(
              existingOperation.id,
              existingOperation.retryCount + 1,
              e.toString());
        }
      }
      rethrow;
    }
  }
}
