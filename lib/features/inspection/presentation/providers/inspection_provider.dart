// features/inspection/presentation/providers/inspection_provider.dart
import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:safe_driving_app/features/inspection/domain/usecases/inspection.dart';

class InspectionProvider with ChangeNotifier {
  late SubmitInspection submitInspection;

  InspectionProvider({required InspectionRepository repository}) {
    submitInspection = SubmitInspection(repository);
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> submitInspectionData(
    InspectionEntity inspection, {
    bool isRetry = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await submitInspection(inspection, isRetry: isRetry);
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
