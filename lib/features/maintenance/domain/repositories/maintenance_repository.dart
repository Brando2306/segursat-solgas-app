import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';

abstract class MaintenanceRepository {
  Future<void> submitMaintenance(
    MaintenanceEntity maintenance, {
    bool isRetry = false,
  });
}
