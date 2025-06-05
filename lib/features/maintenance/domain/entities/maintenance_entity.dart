import 'dart:math';

class MaintenanceEntity {
  final dynamic id;
  final dynamic driverIdNumber;
  final dynamic driverFullName;
  final dynamic unitName;
  final dynamic odometer;
  final dynamic nextMaintenanceOdometer;
  final dynamic durationTime;
  final dynamic timestamp;
  final dynamic odometerImagePath;
  final List<String> additionalImagePaths;

  MaintenanceEntity({
    String? id,
    required this.driverIdNumber,
    required this.driverFullName,
    required this.unitName,
    required this.odometer,
    required this.nextMaintenanceOdometer,
    required this.durationTime,
    required this.timestamp,
    required this.odometerImagePath,
    required this.additionalImagePaths,
  }) : id = id ?? _generateTemporaryId();

  static String _generateTemporaryId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id_number': driverIdNumber,
      'driver_fullname': driverFullName,
      'unit_name': unitName,
      'odometer': odometer,
      'next_maintenance_odometer': nextMaintenanceOdometer,
      'duration_time': durationTime,
      'timestamp': timestamp,
      'odometer_image_path': odometerImagePath,
      'additional_image_paths': additionalImagePaths,
    };
  }

  factory MaintenanceEntity.fromJson(Map<String, dynamic> json) {
    return MaintenanceEntity(
      id: json['id'],
      driverIdNumber: json['driver_id_number'],
      driverFullName: json['driver_fullname'],
      unitName: json['unit_name'],
      odometer: json['odometer'],
      nextMaintenanceOdometer: json['next_maintenance_odometer'],
      durationTime: json['duration_time'],
      timestamp: json['timestamp'],
      odometerImagePath: json['odometer_image_path'],
      additionalImagePaths: List<String>.from(json['additional_image_paths']),
    );
  }
}
