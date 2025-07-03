import 'package:dio/dio.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/endpoints.dart';

abstract class MaintenanceRemoteDataSource {
  Future<void> uploadMaintenance(MaintenanceEntity maintenance);
}

class MaintenanceRemoteDataSourceImpl implements MaintenanceRemoteDataSource {
  final Dio dio;

  MaintenanceRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> uploadMaintenance(MaintenanceEntity maintenance) async {
    final formData = FormData.fromMap({
      'timestamp': getDate(),
      'driver_id_number': maintenance.driverIdNumber,
      'driver_fullname': maintenance.driverFullName,
      'unit_name': maintenance.unitName,
      'duration_time': maintenance.durationTime,
      'next_maintenance_odometer': maintenance.nextMaintenanceOdometer,
      'odometer': maintenance.odometer,
      'image1': await MultipartFile.fromFile(maintenance.odometerImagePath),
    });

    // Agregar imágenes adicionales si existen
    for (var i = 0; i < maintenance.additionalImagePaths.length; i++) {
      formData.files.add(MapEntry(
        'image${i + 2}',
        await MultipartFile.fromFile(maintenance.additionalImagePaths[i]),
      ));
    }

    final response = await dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.MAINTANCE_UPLOAD}',
      data: formData,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200 || response.data['status'] != 'OK') {
      throw Exception('Failed to upload maintenance: ${response.data}');
    }
  }
}
