import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';

class IncidentProvider with ChangeNotifier {
  final RouteRepository repository;

  IncidentProvider({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> submitIncident(IncidentRouteEntity incident) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.sendIncident(incident);
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
