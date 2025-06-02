import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';
import 'package:safe_driving_app/features/driver/domain/repositories/driver_repository.dart';
import 'package:safe_driving_app/features/driver/domain/usecases/get_driver.dart';

class DriverProvider with ChangeNotifier {
  late GetDriver getDriver;

  DriverProvider({required DriverRepository driverRepository}) {
    getDriver = GetDriver(driverRepository);
  }

  DriverEntity? _driver;
  DriverEntity? get driver => _driver;

  dynamic _error;
  dynamic get error => _error;

  Future<void> fetchDriver(String idNumber) async {
    try {
      _error = null;
      _driver = await getDriver(idNumber);
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }
}
