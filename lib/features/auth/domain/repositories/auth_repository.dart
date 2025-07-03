import 'package:safe_driving_app/features/auth/domain/entities/auth_user_entity.dart';

abstract class AuthRepository {
  Future<bool> isAuthenticated();
  Future<void> saveSession(AuthUser user);
  Future<AuthUser> getCurrentUser();
  Future<void> clearSession();
}
