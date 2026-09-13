import 'dart:async';

import 'package:netlearn/data/models/progress_model.dart';
import 'package:netlearn/data/models/reflection_model.dart';
import 'package:netlearn/data/models/user_model.dart';
import 'package:netlearn/data/repositories/auth_repository.dart';
import 'package:netlearn/data/repositories/progress_repository.dart';

/// Progress repository stub with a controllable realtime stream and a switch
/// to make writes fail, so the sync behaviour can be asserted without Firebase.
class FakeProgressRepository extends ProgressRepository {
  FakeProgressRepository({this.realtime = true});

  final bool realtime;
  bool failWrites = false;
  final List<ProgressModel> stored = [];
  final _controller = StreamController<List<ProgressModel>>.broadcast();

  @override
  bool get supportsRealtime => realtime;

  @override
  Stream<List<ProgressModel>> watchProgress(String userId) => _controller.stream;

  void emit(List<ProgressModel> progress) => _controller.add(progress);

  Future<void> close() => _controller.close();

  @override
  Future<List<ProgressModel>> getProgress(String userId) async => List.of(stored);

  @override
  Future<void> saveProgress(String userId, ProgressModel progress) async {
    if (failWrites) throw Exception('offline');
    stored.removeWhere((p) => p.unitId == progress.unitId);
    stored.add(progress);
  }

  @override
  Future<void> saveQuizScore(String userId, String unitId,
      {int? pretestScore, int? checkpointScore, int? finalScore, int? practiceScore}) async {
    if (failWrites) throw Exception('offline');
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async => const [];

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {}

  @override
  Future<void> resetAllProgress(String userId) async => stored.clear();

  @override
  Future<ReflectionModel?> getReflection(String userId) async => null;

  @override
  Future<void> saveReflection(String userId, ReflectionModel reflection) async {
    if (failWrites) throw Exception('offline');
  }
}

/// Auth repository stub that records writes and can fail on demand.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this.user);

  UserModel? user;
  bool failWrites = false;
  int updateCalls = 0;

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<void> updateUser(UserModel updated) async {
    updateCalls++;
    if (failWrites) throw Exception('offline');
    user = updated;
  }

  @override
  Future<UserModel?> addXp(String userId, int amount) async {
    if (failWrites) throw Exception('offline');
    final current = user!;
    final newXp = current.xp + amount;
    user = current.copyWith(xp: newXp, level: (newXp ~/ 100) + 1);
    return user;
  }

  @override
  Future<UserModel?> login({required String username, required String password}) async => user;

  @override
  Future<UserModel?> register({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async => user;

  @override
  Future<UserModel?> createUser({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async => user;

  @override
  Future<void> deleteUser(String userId) async {}

  @override
  Future<List<UserModel>> getAllUsers() async => [if (user != null) user!];

  @override
  Future<void> logout() async {}
}


UserModel testStudent() => UserModel(
      id: 'siswa1',
      displayName: 'Siswa Satu',
      phoneNumber: '08123',
      xp: 40,
      lastActive: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
