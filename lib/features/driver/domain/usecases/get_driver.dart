import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';
import 'package:safe_driving_app/features/driver/domain/repositories/driver_repository.dart';

class GetDriver {
  final DriverRepository repository;

  GetDriver(this.repository);

  Future<DriverEntity> call(String idNumber) async {
    return await repository.getDriver(idNumber);
  }
}
