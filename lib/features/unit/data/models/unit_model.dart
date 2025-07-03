import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';

class UnitModel extends UnitEntity {
  UnitModel({
    super.id,
    super.name,
    super.description,
    super.lastOdometer,
    super.technicalReviewExpiration,
    super.soatExpiration,
    super.insuranceExpiration,
    super.lastRoute,
    super.lastRouteStatus,
    super.lastInitialInspectionDate,
    super.annotations,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      lastOdometer: json['last_odometer'],
      technicalReviewExpiration: json['technical_review_expiration_date'],
      soatExpiration: json['soat_expiration_date'],
      insuranceExpiration: json['insurance_expiration_date'],
      lastRoute: json['last_route'],
      lastRouteStatus: json['last_route_status'],
      lastInitialInspectionDate: json['last_initial_inspection_date'],
      annotations: json['annotations'],
    );
  }
}
