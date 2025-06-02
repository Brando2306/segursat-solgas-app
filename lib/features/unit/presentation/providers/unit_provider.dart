import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';
import 'package:safe_driving_app/features/unit/domain/repositories/unit_repository.dart';
import 'package:safe_driving_app/features/unit/domain/usecases/get_unit.dart';

class UnitProvider with ChangeNotifier {
  late GetUnit getUnit;

  UnitProvider({required UnitRepository unitRepository}) {
    getUnit = GetUnit(unitRepository);
  }

  UnitEntity? _unit;
  UnitEntity? get unit => _unit;

  dynamic _error;
  dynamic get error => _error;

  Future<void> fetchUnit(String licensePlate) async {
    try {
      _error = null;
      _unit = await getUnit(licensePlate);
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }
}
