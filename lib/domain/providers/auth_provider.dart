import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../services/streak_service.dart';
import 'repository_providers.dart';

/// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final bool isNewUser;
  final String? authError;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.isNewUser = false,
    this.authError,
  });

  static const _unset = Object();

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    bool? isNewUser,
    Object? authError = _unset,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isNewUser: isNewUser ?? this.isNewUser,
      authError: identical(authError, _unset) ? this.authError : authError as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  /// Restore existing login session from local persistence.
  Future<void> initializeSession() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, authError: null);

    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = AuthState(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          isNewUser: false,
        );
        await _refreshDailyStreak();
        return;
      }
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, authError: e.toString());
    }
  }

  /// Login
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, authError: null);

    try {
      final u = username.trim();
      final p = password.trim();
      if (u.toLowerCase() == 'admin' && p.toLowerCase() == 'admin') {
        final now = DateTime.now();
        final adminUser = UserModel(
          id: 'admin',
          displayName: 'Administrator',
          phoneNumber: 'admin',
          role: 'admin',
          password: 'admin',
          lastActive: now,
          createdAt: now,
        );
        state = AuthState(
          user: adminUser,
          isLoading: false,
          isLoggedIn: true,
          isNewUser: false,
        );
        return true;
      }

      final user = await _repo.login(username: u, password: p);
      if (user != null) {
        state = AuthState(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          isNewUser: false,
        );
        await _refreshDailyStreak();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, authError: e.toString());
    }
    return false;
  }

  /// Register
  Future<bool> register(
    String name,
    String username,
    String phoneNumber,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, authError: null);

    try {
      final user = await _repo.register(
        name: name,
        username: username,
        phoneNumber: phoneNumber,
        password: password,
      );
      if (user != null) {
        state = AuthState(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          isNewUser: true,
        );
        await _refreshDailyStreak();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, authError: e.toString());
    }
    return false;
  }

  /// Reset Auth Error
  void clearError() {
    state = state.copyWith(authError: null);
  }

  void markNewUserTutorialSeen() {
    if (!state.isNewUser) return;
    state = state.copyWith(isNewUser: false);
  }

  // --- Profile methods ---

  void addXP(int amount) {
    if (state.user == null || amount <= 0) return;
    final current = state.user!;
    final newXp = current.xp + amount;
    final newLevel = (newXp ~/ 100) + 1;
    final updated = current.copyWith(xp: newXp, level: newLevel);
    state = state.copyWith(user: updated, isLoggedIn: true);
    _repo.updateUser(updated);
  }

  void updateStreak(int days) {
    if (state.user == null) return;
    final updated = state.user!.copyWith(streak: days);
    state = state.copyWith(
      user: updated,
      isLoggedIn: true,
    );
    _repo.updateUser(updated);
  }

  /// Perbarui streak harian berdasarkan tanggal aktivitas terakhir.
  Future<void> _refreshDailyStreak() async {
    final user = state.user;
    if (user == null || user.role == 'admin') return;

    final now = DateTime.now();
    final result = StreakService.refresh(
      currentStreak: user.streak,
      lastActive: user.lastActive,
      now: now,
    );

    final updated = user.copyWith(
      streak: result.streak,
      lastActive: now,
    );

    final streakChanged = updated.streak != user.streak;
    final lastActiveDayChanged = _isDifferentDay(updated.lastActive, user.lastActive);

    if (streakChanged || lastActiveDayChanged) {
      await _repo.updateUser(updated);
    }

    state = state.copyWith(user: updated, isLoggedIn: true);
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year != localB.year ||
        localA.month != localB.month ||
        localA.day != localB.day;
  }

  void toggleDarkMode() {
    if (state.user == null) return;
    final s = state.user!.settings;
    state = state.copyWith(
      user: state.user!.copyWith(settings: s.copyWith(darkMode: !s.darkMode)),
      isLoggedIn: true,
    );
  }

  void toggleAudio() {
    if (state.user == null) return;
    final s = state.user!.settings;
    state = state.copyWith(
      user: state.user!.copyWith(
        settings: s.copyWith(audioEnabled: !s.audioEnabled),
      ),
      isLoggedIn: true,
    );
  }

  void toggleMusic() {
    if (state.user == null) return;
    final s = state.user!.settings;
    state = state.copyWith(
      user: state.user!.copyWith(
        settings: s.copyWith(musicEnabled: !s.musicEnabled),
      ),
      isLoggedIn: true,
    );
  }

  /// Reset XP, level, streak, dan badge profil seperti pengguna baru.
  Future<void> resetUserLearningProfile() async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(
      xp: 0,
      level: 1,
      streak: 0,
      unlockedBadgeIds: const [],
      lastActive: DateTime.now(),
    );
    await _repo.updateUser(updated);
    state = state.copyWith(
      user: updated,
      isLoggedIn: true,
      isNewUser: true,
    );
  }

  void logout() {
    _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
