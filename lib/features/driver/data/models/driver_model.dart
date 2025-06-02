import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  DriverModel({
    super.id,
    super.idNumber,
    super.lastName,
    super.firstName,
    super.licenseExpiration,
    super.annotations,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      idNumber: json['id_number'],
      lastName: json['lastname'],
      firstName: json['firstname'],
      licenseExpiration: json['driver_license_expiration_date'],
      annotations: json['annotations'],
    );
  }
}
