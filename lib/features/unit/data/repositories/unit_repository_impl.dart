import 'package:safe_driving_app/features/unit/data/datasources/unit_remote_datasource.dart';
import 'package:safe_driving_app/features/unit/data/models/unit_model.dart';
import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';
import 'package:safe_driving_app/features/unit/domain/repositories/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDataSource remoteDataSource;

  UnitRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UnitEntity> getUnit(String licensePlate) async {
    try {
      final unitData = await remoteDataSource.getUnit(licensePlate);

      if (unitData.containsKey('detail')) {
        throw unitData;
      }

      return UnitModel.fromJson(unitData);
    } catch (e) {
      rethrow;
    }
  }
}
