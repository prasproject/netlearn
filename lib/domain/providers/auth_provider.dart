import 'dart:async';

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

  /// Set when a profile write (XP, streak, settings) failed to reach the
  /// database, so the UI can tell the user instead of silently drifting.
  final String? syncError;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.isNewUser = false,
    this.authError,
    this.syncError,
  });

  static const _unset = Object();

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    bool? isNewUser,
    Object? authError = _unset,
    Object? syncError = _unset,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isNewUser: isNewUser ?? this.isNewUser,
      authError: identical(authError, _unset) ? this.authError : authError as String?,
      syncError: identical(syncError, _unset) ? this.syncError : syncError as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  StreamSubscription<UserModel?>? _userSub;
  String? _watchedUserId;

  /// Keep the in-memory user glued to the database record. Without this the app
  /// shows the locally cached profile while Firebase already holds newer XP,
  /// streak, or settings (e.g. changed on another device or reset by admin).
  void _bindUserStream(String userId) {
    if (!_repo.supportsRealtime) return;
    if (_watchedUserId == userId && _userSub != null) return;
    _userSub?.cancel();
    _watchedUserId = userId;
    _userSub = _repo.watchUser(userId).listen(
      (remote) {
        if (!mounted || remote == null) return;
        if (state.user?.id != remote.id) return;
        state = state.copyWith(user: remote, isLoggedIn: true, syncError: null);
      },
      onError: (Object _) {
        if (!mounted) return;
        state = state.copyWith(
          syncError: 'Gagal sinkron profil. Periksa koneksi internet.',
        );
      },
    );
  }

  void _unbindUserStream() {
    _userSub?.cancel();
    _userSub = null;
    _watchedUserId = null;
  }

  void clearSyncError() {
    if (!mounted || state.syncError == null) return;
    state = state.copyWith(syncError: null);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

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
        _bindUserStream(user.id);
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
        _bindUserStream(user.id);
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
    String password, {
    String? schoolName,
  }) async {
    state = state.copyWith(isLoading: true, authError: null);

    try {
      final user = await _repo.register(
        name: name,
        username: username,
        phoneNumber: phoneNumber,
        password: password,
        schoolName: schoolName,
      );
      if (user != null) {
        state = AuthState(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          isNewUser: true,
        );
        _bindUserStream(user.id);
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

  /// Award XP. The increment happens in a database transaction so two rewards
  /// fired in quick succession can't overwrite each other, and the value shown
  /// on screen is the value the database confirmed.
  Future<void> addXP(int amount) async {
    final current = state.user;
    if (current == null || amount <= 0) return;
    if (current.role == 'admin') return;

    // Optimistic update for instant feedback...
    final optimistic = current.copyWith(
      xp: current.xp + amount,
      level: ((current.xp + amount) ~/ 100) + 1,
    );
    state = state.copyWith(user: optimistic, isLoggedIn: true, syncError: null);

    try {
      final stored = await _repo.addXp(current.id, amount);
      if (!mounted) return;
      if (stored != null) {
        // ...then reconcile with whatever the database actually holds.
        state = state.copyWith(user: stored, isLoggedIn: true);
        return;
      }
      // Backend without transaction support: fall back to a plain write.
      await _repo.updateUser(optimistic);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        user: current,
        isLoggedIn: true,
        syncError: 'XP gagal disimpan. Periksa koneksi internet.',
      );
    }
  }

  Future<void> updateStreak(int days) async {
    final current = state.user;
    if (current == null) return;
    final updated = current.copyWith(streak: days);
    state = state.copyWith(user: updated, isLoggedIn: true);
    await _persist(updated, previous: current);
  }

  /// Write [user] and roll the state back to [previous] if the write fails.
  Future<bool> _persist(UserModel user, {required UserModel previous}) async {
    try {
      await _repo.updateUser(user);
      if (mounted) state = state.copyWith(syncError: null);
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        user: previous,
        isLoggedIn: true,
        syncError: 'Perubahan gagal disimpan. Periksa koneksi internet.',
      );
      return false;
    }
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

  Future<void> toggleDarkMode() =>
      _updateSettings((s) => s.copyWith(darkMode: !s.darkMode));

  Future<void> toggleAudio() =>
      _updateSettings((s) => s.copyWith(audioEnabled: !s.audioEnabled));

  Future<void> toggleMusic() =>
      _updateSettings((s) => s.copyWith(musicEnabled: !s.musicEnabled));

  /// Explicitly set the audio preferences (used by the audio provider so the
  /// switch on screen, the player, and the database never disagree).
  Future<void> setAudioPreferences({bool? sfxEnabled, bool? musicEnabled}) {
    return _updateSettings(
      (s) => s.copyWith(audioEnabled: sfxEnabled, musicEnabled: musicEnabled),
    );
  }

  /// Apply a settings change locally **and** persist it, rolling back on error.
  Future<void> _updateSettings(
    UserSettings Function(UserSettings current) transform,
  ) async {
    final current = state.user;
    if (current == null) return;
    final next = transform(current.settings);
    if (next.darkMode == current.settings.darkMode &&
        next.audioEnabled == current.settings.audioEnabled &&
        next.musicEnabled == current.settings.musicEnabled &&
        next.language == current.settings.language) {
      return;
    }
    final updated = current.copyWith(settings: next);
    state = state.copyWith(user: updated, isLoggedIn: true);
    if (current.role == 'admin') return; // admin is a local-only account
    await _persist(updated, previous: current);
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
    _unbindUserStream();
    _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
