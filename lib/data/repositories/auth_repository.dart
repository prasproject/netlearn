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
    String? schoolName,
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

  /// Live stream of the user record. Realtime implementations override this so
  /// XP, level, streak, and settings shown in the UI always match the database.
  Stream<UserModel?> watchUser(String userId) =>
      const Stream<UserModel?>.empty();

  /// Atomically add [amount] XP and return the stored user afterwards.
  ///
  /// Implemented as a transaction where the backend supports it so two quick
  /// rewards can never overwrite each other. Returns null when unsupported.
  Future<UserModel?> addXp(String userId, int amount) async => null;

  /// Whether this implementation emits realtime updates.
  bool get supportsRealtime => false;
}
