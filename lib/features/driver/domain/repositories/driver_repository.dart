import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';

abstract class DriverRepository {
  Future<DriverEntity> getDriver(String idNumber);
}
