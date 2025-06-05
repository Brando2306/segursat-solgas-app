import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/utils/endpoints.dart';

abstract class InspectionRemoteDataSource {
  Future<void> uploadInspection(InspectionEntity inspection);
}

class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  final Dio dio;

  InspectionRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> uploadInspection(InspectionEntity inspection) async {
    final formData = FormData.fromMap({
      'timestamp': inspection.timestamp,
      'latitude': inspection.latitude,
      'longitude': inspection.longitude,
      'driver_id_number': inspection.driverIdNumber,
      'driver_fullname': inspection.driverFullName,
      'unit_name': inspection.unitName,
      'duration_time': 123151, // Valor temporal
      'odometer': inspection.odometer,
      'questions': json.encode(inspection.questions),
    });

    // Agregar imágenes condicionalmente
    if (inspection.odometerImagePath != null) {
      formData.files.add(MapEntry(
        'image1',
        await MultipartFile.fromFile(inspection.odometerImagePath!),
      ));
    }

    if (inspection.selfieImagePath != null) {
      formData.files.add(MapEntry(
        'image2',
        await MultipartFile.fromFile(inspection.selfieImagePath!),
      ));
    }

    if (inspection.panoramicImagePath != null) {
      formData.files.add(MapEntry(
        'image3',
        await MultipartFile.fromFile(inspection.panoramicImagePath!),
      ));
    }

    if (inspection.seatbeltImagePath != null) {
      formData.files.add(MapEntry(
        'image4',
        await MultipartFile.fromFile(inspection.seatbeltImagePath!),
      ));
    }

    if (inspection.accessoriesImagePath != null) {
      formData.files.add(MapEntry(
        'image5',
        await MultipartFile.fromFile(inspection.accessoriesImagePath!),
      ));
    }

    final response = await dio.post(
      'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSPECTION_UPLOAD}',
      data: formData,
      options: Options(headers: {
        'Authorization': ENDPOINTS.auth(),
      }),
    );

    if (response.statusCode != 200 || response.data['status'] != 'OK') {
      throw Exception('Failed to upload inspection: ${response.data}');
    }
  }
}
