import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';

class ControlStopProvider with ChangeNotifier {
  final RouteRepository repository;

  ControlStopProvider({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> submitStop(StopRouteEntity stop) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.sendRouteStop(stop);
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
