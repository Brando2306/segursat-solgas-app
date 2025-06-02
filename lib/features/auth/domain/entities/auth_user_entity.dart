import 'dart:convert';

class AuthUser {
  final dynamic name;
  final dynamic lastName;
  final dynamic document;
  final dynamic licensePlate;
  final dynamic unitId;
  final dynamic lastInitialInspectionDate;
  final dynamic lastOdometer;
  final dynamic technicalReviewExpirationDate;
  final dynamic soatExpirationDate;
  final dynamic insuranceExpirationDate;
  final dynamic lastRoute;
  final dynamic lastRouteStatus;

  const AuthUser({
    this.name,
    this.lastName,
    this.document,
    this.licensePlate,
    this.unitId,
    this.lastInitialInspectionDate,
    this.lastOdometer,
    this.technicalReviewExpirationDate,
    this.soatExpirationDate,
    this.insuranceExpirationDate,
    this.lastRoute,
    this.lastRouteStatus,
  });

  AuthUser copyWith({
    dynamic name,
    dynamic lastName,
    dynamic document,
    dynamic licensePlate,
    dynamic unitId,
    dynamic lastInitialInspectionDate,
    dynamic lastOdometer,
    dynamic technicalReviewExpirationDate,
    dynamic soatExpirationDate,
    dynamic insuranceExpirationDate,
    dynamic lastRoute,
    dynamic lastRouteStatus,
  }) {
    return AuthUser(
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      document: document ?? this.document,
      licensePlate: licensePlate ?? this.licensePlate,
      unitId: unitId ?? this.unitId,
      lastInitialInspectionDate:
          lastInitialInspectionDate ?? this.lastInitialInspectionDate,
      lastOdometer: lastOdometer ?? this.lastOdometer,
      technicalReviewExpirationDate:
          technicalReviewExpirationDate ?? this.technicalReviewExpirationDate,
      soatExpirationDate: soatExpirationDate ?? this.soatExpirationDate,
      insuranceExpirationDate:
          insuranceExpirationDate ?? this.insuranceExpirationDate,
      lastRoute: lastRoute ?? this.lastRoute,
      lastRouteStatus: lastRouteStatus ?? this.lastRouteStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'document': document,
      'licensePlate': licensePlate,
      'unitId': unitId,
      'lastInitialInspectionDate': lastInitialInspectionDate,
      'lastOdometer': lastOdometer,
      'technicalReviewExpirationDate': technicalReviewExpirationDate,
      'soatExpirationDate': soatExpirationDate,
      'insuranceExpirationDate': insuranceExpirationDate,
      'lastRoute': lastRoute,
      'lastRouteStatus': lastRouteStatus,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      name: map['name'],
      lastName: map['lastName'],
      document: map['document'],
      licensePlate: map['licensePlate'],
      unitId: map['unitId'],
      lastInitialInspectionDate: map['lastInitialInspectionDate'],
      lastOdometer: map['lastOdometer'],
      technicalReviewExpirationDate: map['technicalReviewExpirationDate'],
      soatExpirationDate: map['soatExpirationDate'],
      insuranceExpirationDate: map['insuranceExpirationDate'],
      lastRoute: map['lastRoute'],
      lastRouteStatus: map['lastRouteStatus'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source));
}

// import 'dart:convert';

// class AuthUser {
//   final String name;
//   final String lastName;
//   final String document;
//   final String licensePlate;
//   final int unitId;
//   final String lastInitialInspectionDate;
//   final String lastOdometer;
//   final String technicalReviewExpirationDate;
//   final String soatExpirationDate;
//   final String insuranceExpirationDate;
//   final dynamic lastRoute;
//   final dynamic lastRouteStatus;

//   const AuthUser({
//     required this.name,
//     required this.lastName,
//     required this.document,
//     required this.licensePlate,
//     required this.unitId,
//     required this.lastInitialInspectionDate,
//     required this.lastOdometer,
//     required this.technicalReviewExpirationDate,
//     required this.soatExpirationDate,
//     required this.insuranceExpirationDate,
//     required this.lastRoute,
//     required this.lastRouteStatus,
//   });

//   AuthUser copyWith({
//     String? name,
//     String? lastName,
//     String? document,
//     String? licensePlate,
//     int? unitId,
//     String? lastInitialInspectionDate,
//     String? lastOdometer,
//     String? technicalReviewExpirationDate,
//     String? soatExpirationDate,
//     String? insuranceExpirationDate,
//     dynamic lastRoute,
//     dynamic lastRouteStatus,
//   }) {
//     return AuthUser(
//       name: name ?? this.name,
//       lastName: lastName ?? this.lastName,
//       document: document ?? this.document,
//       licensePlate: licensePlate ?? this.licensePlate,
//       unitId: unitId ?? this.unitId,
//       lastInitialInspectionDate: lastInitialInspectionDate ?? this.lastInitialInspectionDate,
//       lastOdometer: lastOdometer ?? this.lastOdometer,
//       technicalReviewExpirationDate: technicalReviewExpirationDate ?? this.technicalReviewExpirationDate,
//       soatExpirationDate: soatExpirationDate ?? this.soatExpirationDate,
//       insuranceExpirationDate: insuranceExpirationDate ?? this.insuranceExpirationDate,
//       lastRoute: lastRoute ?? this.lastRoute,
//       lastRouteStatus: lastRouteStatus ?? this.lastRouteStatus,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'lastName': lastName,
//       'document': document,
//       'licensePlate': licensePlate,
//       'unitId': unitId,
//       'lastInitialInspectionDate': lastInitialInspectionDate,
//       'lastOdometer': lastOdometer,
//       'technicalReviewExpirationDate': technicalReviewExpirationDate,
//       'soatExpirationDate': soatExpirationDate,
//       'insuranceExpirationDate': insuranceExpirationDate,
//       'lastRoute': lastRoute,
//       'lastRouteStatus': lastRouteStatus,
//     };
//   }

//   factory AuthUser.fromMap(Map<String, dynamic> map) {
//     return AuthUser(
//       name: map['name'] as String,
//       lastName: map['lastName'] as String,
//       document: map['document'] as String,
//       licensePlate: map['licensePlate'] as String,
//       unitId: map['unitId'] is int ? map['unitId'] as int : int.parse(map['unitId'].toString()),
//       lastInitialInspectionDate: map['lastInitialInspectionDate'] as String,
//       lastOdometer: map['lastOdometer'] as String,
//       technicalReviewExpirationDate: map['technicalReviewExpirationDate'] as String,
//       soatExpirationDate: map['soatExpirationDate'] as String,
//       insuranceExpirationDate: map['insuranceExpirationDate'] as String,
//       lastRoute: map['lastRoute'],
//       lastRouteStatus: map['lastRouteStatus'],
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory AuthUser.fromJson(String source) =>
//       AuthUser.fromMap(json.decode(source));
// }