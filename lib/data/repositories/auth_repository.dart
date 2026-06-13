import '../models/user_model.dart';

/// Abstract auth repository — swap between mock and Firebase implementations.
abstract class AuthRepository {
  /// Login with username and password
  Future<UserModel?> login({
    required String username,
    required String password,
  });

  /// Register new user
  Future<UserModel?> register({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  });

  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> updateUser(UserModel user);
  Future<UserModel?> createUser({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  });
  Future<void> deleteUser(String userId);
  Future<List<UserModel>> getAllUsers();
}
