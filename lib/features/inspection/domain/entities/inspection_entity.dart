import 'dart:convert';
import 'dart:math';

class InspectionEntity {
  final String id;
  final String driverIdNumber;
  final String driverFullName;
  final String unitName;
  final String odometer;
  final int timestamp;
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> questions;
  final String? odometerImagePath;
  final String? selfieImagePath;
  final String? panoramicImagePath;
  final String? seatbeltImagePath;
  final String? accessoriesImagePath;

  InspectionEntity({
    String? id,
    required this.driverIdNumber,
    required this.driverFullName,
    required this.unitName,
    required this.odometer,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.questions,
    this.odometerImagePath,
    this.selfieImagePath,
    this.panoramicImagePath,
    this.seatbeltImagePath,
    this.accessoriesImagePath,
  }) : id = id ?? _generateTemporaryId();

  static String _generateTemporaryId() {
    return 'insp_temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id_number': driverIdNumber,
      'driver_fullname': driverFullName,
      'unit_name': unitName,
      'odometer': odometer,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'questions': json.encode(questions),
      'odometer_image_path': odometerImagePath,
      'selfie_image_path': selfieImagePath,
      'panoramic_image_path': panoramicImagePath,
      'seatbelt_image_path': seatbeltImagePath,
      'accessories_image_path': accessoriesImagePath,
    };
  }

  factory InspectionEntity.fromJson(Map<String, dynamic> jsonMap) {
    return InspectionEntity(
      id: jsonMap['id'],
      driverIdNumber: jsonMap['driver_id_number'],
      driverFullName: jsonMap['driver_fullname'],
      unitName: jsonMap['unit_name'],
      odometer: jsonMap['odometer'],
      timestamp: jsonMap['timestamp'],
      latitude: jsonMap['latitude'],
      longitude: jsonMap['longitude'],
      questions:
          List<Map<String, dynamic>>.from(json.decode(jsonMap['questions'])),
      odometerImagePath: jsonMap['odometer_image_path'],
      selfieImagePath: jsonMap['selfie_image_path'],
      panoramicImagePath: jsonMap['panoramic_image_path'],
      seatbeltImagePath: jsonMap['seatbelt_image_path'],
      accessoriesImagePath: jsonMap['accessories_image_path'],
    );
  }
}
