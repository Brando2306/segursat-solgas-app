import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';

abstract class UnitRepository {
  Future<UnitEntity> getUnit(String licensePlate);
}
