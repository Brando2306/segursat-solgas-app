import 'package:safe_driving_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:safe_driving_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:safe_driving_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<bool> isAuthenticated() async {
    return localDataSource.isAuthenticated();
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    return localDataSource.getCurrentUser();
  }

  @override
  Future<void> saveSession(AuthUser user) async {
    await localDataSource.saveSession(user);
  }

  @override
  Future<void> clearSession() async {
    await localDataSource.clearSession();
  }
}
