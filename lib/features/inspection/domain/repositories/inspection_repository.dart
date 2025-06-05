import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';

abstract class InspectionRepository {
  Future<void> submitInspection(
    InspectionEntity inspection, {
    bool isRetry = false,
  });
}
