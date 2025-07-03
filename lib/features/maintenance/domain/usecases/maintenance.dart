import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/maintenance/domain/repositories/maintenance_repository.dart';

class SubmitMaintenance {
  final MaintenanceRepository repository;

  SubmitMaintenance(this.repository);

  Future<void> call(MaintenanceEntity maintenance) async {
    return await repository.submitMaintenance(maintenance);
  }
}
