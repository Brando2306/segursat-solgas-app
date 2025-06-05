import 'package:safe_driving_app/features/inspection/data/datasources/inspection_remote_datasource.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionRemoteDataSource remoteDataSource;
  final OfflineOperationsRepository offlineOperationsRepository;

  InspectionRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineOperationsRepository,
  });

  @override
  Future<void> submitInspection(
    InspectionEntity inspection, {
    bool isRetry = false,
  }) async {
    try {
      await remoteDataSource.uploadInspection(inspection);
    } catch (e) {
      // Solo maneja offline si NO es un reintento
      if (!isRetry) {
        final existingOperation = await offlineOperationsRepository
            .getInspectionOperationByUniqueKey(inspection.id);
        if (existingOperation == null) {
          await offlineOperationsRepository.saveOperation(
            OfflineOperation(
              type: OfflineOperationType.inspection,
              data: inspection.toJson(),
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
