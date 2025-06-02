import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';
import 'package:safe_driving_app/features/unit/domain/repositories/unit_repository.dart';

class GetUnit {
  final UnitRepository repository;

  GetUnit(this.repository);

  Future<UnitEntity> call(String licensePlate) async {
    try {
      return await repository.getUnit(licensePlate);
    } catch (e) {
      rethrow;
    }
  }
}
