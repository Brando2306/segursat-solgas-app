import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:safe_driving_app/features/maintenance/domain/usecases/maintenance.dart';

class MaintenanceProvider with ChangeNotifier {
  late SubmitMaintenance submitMaintenance;

  MaintenanceProvider({required MaintenanceRepository repository}) {
    submitMaintenance = SubmitMaintenance(repository);
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> submitMaintenanceData(MaintenanceEntity maintenance) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await submitMaintenance(maintenance);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
