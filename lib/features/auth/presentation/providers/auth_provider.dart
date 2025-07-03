import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:safe_driving_app/features/auth/domain/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository authRepository;

  AuthProvider({required this.authRepository});

  AuthUser? _currentUser;
  bool _isAuthenticated = false;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await authRepository.isAuthenticated();
    if (_isAuthenticated) {
      _currentUser = await authRepository.getCurrentUser();
    }
    notifyListeners();
  }

  bool _submitValidation = false;
  bool _nextButtonValidation = false;

  bool get submitValidation => _submitValidation;
  bool get nextButtonValidation => _nextButtonValidation;

  void setSubmitValidation(bool value) {
    _submitValidation = value;
    notifyListeners();
  }

  void setNextButtonValidation(bool value) {
    _nextButtonValidation = value;
    notifyListeners();
  }

  bool _visible = false;
  bool get visible => _visible;

  void toggleVisibility() {
    _visible = !_visible;
    notifyListeners();
  }

  void setVisible(bool value) {
    _visible = value;
    notifyListeners();
  }

  bool _checkSelected = false;
  bool get checkSelected => _checkSelected;

  void setCheckSelected(bool value) {
    _checkSelected = value;
    notifyListeners();
  }

  Future<void> login({
    String? name,
    String? lastName,
    String? document,
    String? licensePlate,
    int? unitId,
    String? lastInitialInspectionDate,
    int? lastOdometer,
    String? technicalReviewExpirationDate,
    String? soatExpirationDate,
    String? insuranceExpirationDate,
    dynamic lastRoute,
    dynamic lastRouteStatus,
  }) async {
    final user = AuthUser(
      name: name,
      lastName: lastName,
      document: document,
      licensePlate: licensePlate,
      unitId: unitId,
      lastInitialInspectionDate: lastInitialInspectionDate,
      lastOdometer: lastOdometer,
      technicalReviewExpirationDate: technicalReviewExpirationDate,
      soatExpirationDate: soatExpirationDate,
      insuranceExpirationDate: insuranceExpirationDate,
      lastRoute: lastRoute,
      lastRouteStatus: lastRouteStatus,
    );

    await authRepository.saveSession(user);
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await authRepository.clearSession();
    _isAuthenticated = false;
    _currentUser = null;
    _submitValidation = false;
    _nextButtonValidation = false;
    notifyListeners();
  }
}
