import 'package:safe_driving_app/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:safe_driving_app/features/driver/data/models/driver_model.dart';
import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';
import 'package:safe_driving_app/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remoteDataSource;

  DriverRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DriverEntity> getDriver(String idNumber) async {
    try {
      final driverData = await remoteDataSource.getDriver(idNumber);

      if (driverData.containsKey('detail')) {
        throw driverData;
      }

      return DriverModel.fromJson(driverData);
    } catch (e) {
      rethrow;
    }
  }
}
