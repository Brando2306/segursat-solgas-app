import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/inspection/domain/repositories/inspection_repository.dart';

class SubmitInspection {
  final InspectionRepository repository;

  SubmitInspection(this.repository);

  Future<void> call(InspectionEntity inspection) async {
    return await repository.submitInspection(inspection);
  }
}
