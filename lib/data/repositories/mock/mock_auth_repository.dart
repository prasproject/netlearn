import '../../models/user_model.dart';
import '../../seed/seed_data.dart';
import '../auth_repository.dart';

/// Mock auth repository — uses SeedData for Phase 1.
/// Simulates Firebase Phone Auth OTP flow.
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final List<UserModel> _users = [
    SeedData.demoAdmin,
    SeedData.demoUser,
  ];

  @override
  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (username == '0000' && password == '0000') {
      _currentUser = SeedData.demoAdmin;
      return _currentUser;
    }

    if (password.length >= 4) {
      _currentUser = SeedData.demoUser.copyWith(phoneNumber: username);
      _users.removeWhere((u) => u.id == _currentUser!.id);
      _users.add(_currentUser!);
      return _currentUser;
    }

    throw Exception('Password salah atau terlalu pendek.');
  }

  @override
  Future<UserModel?> register({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (password.length < 4) {
      throw Exception('Password minimal 4 karakter');
    }

    _currentUser = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
      phoneNumber: phoneNumber,
      lastActive: DateTime.now(),
      createdAt: DateTime.now(),
      role: 'student',
    );
    _users.add(_currentUser!);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx == -1) {
      _users.add(user);
      return;
    }
    _users[idx] = user;
  }

  @override
  Future<UserModel?> createUser({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    final exists = _users.any((u) => u.id == username);
    if (exists) {
      throw Exception('Username sudah dipakai. Silakan gunakan yang lain.');
    }

    final user = UserModel(
      id: username,
      displayName: name,
      phoneNumber: phoneNumber,
      password: password,
      role: 'student',
      lastActive: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return List<UserModel>.from(_users);
  }
}
