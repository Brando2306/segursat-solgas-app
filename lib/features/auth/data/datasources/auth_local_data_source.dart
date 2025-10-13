import 'dart:developer';

import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/features/auth/domain/entities/auth_user_entity.dart';

abstract class AuthLocalDataSource {
  Future<bool> isAuthenticated();
  Future<AuthUser> getCurrentUser();
  Future<void> saveSession(AuthUser user);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<bool> isAuthenticated() async {
    const value = 'personal.document';
    // log('Checking authentication status for key: $value');
    var val = readStorage('personal.document');
    // log('Authentication status: ${val != null}');
    return readStorage('personal.document') != null;
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    return AuthUser(
      name: readStorage('personal.name'),
      lastName: readStorage('personal.lastName'),
      document: readStorage('personal.document'),
      licensePlate: readStorage('personal.licensePlate'),
      unitId: readStorage('personal.unitId'),
      lastInitialInspectionDate:
          readStorage('personal.lastInitialInspectionDate'),
      lastOdometer: readStorage('personal.lastOdometer'),
      technicalReviewExpirationDate:
          readStorage('personal.technicalReviewExpirationDate'),
      soatExpirationDate: readStorage('personal.soatExpirationDate'),
      insuranceExpirationDate: readStorage('personal.insuranceExpirationDate'),
      lastRoute: readStorage('personal.lastRoute'),
      lastRouteStatus: readStorage('personal.lastRouteStatus'),
    );
  }

  @override
  Future<void> saveSession(AuthUser user) async {
    // log('Saving user session: ${user.toJson()}');

    await Future.wait([
      if (user.name != null) writeStorage('personal.name', user.name),
      if (user.lastName != null)
        writeStorage('personal.lastName', user.lastName),
      if (user.document != null)
        writeStorage('personal.document', user.document),
      if (user.licensePlate != null)
        writeStorage('personal.licensePlate', user.licensePlate),
      if (user.unitId != null) writeStorage('personal.unitId', user.unitId),
      if (user.lastInitialInspectionDate != null)
        writeStorage('personal.lastInitialInspectionDate',
            user.lastInitialInspectionDate),
      if (user.lastOdometer != null)
        writeStorage('personal.lastOdometer', user.lastOdometer),
      if (user.technicalReviewExpirationDate != null)
        writeStorage('personal.technicalReviewExpirationDate',
            user.technicalReviewExpirationDate),
      if (user.soatExpirationDate != null)
        writeStorage('personal.soatExpirationDate', user.soatExpirationDate),
      if (user.insuranceExpirationDate != null)
        writeStorage(
            'personal.insuranceExpirationDate', user.insuranceExpirationDate),
      if (user.lastRoute != null)
        writeStorage('personal.lastRoute', user.lastRoute),
      if (user.lastRouteStatus != null)
        writeStorage('personal.lastRouteStatus', user.lastRouteStatus),
    ]);
  }

  @override
  Future<void> clearSession() async {
    cleanPersonalStorage();
  }
}
