import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/simulation_provider.dart';
import '../../domain/providers/repository_providers.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/models/progress_model.dart';

/// Profile Screen — Shows WhatsApp number, settings with audio/music toggles.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final audio = ref.watch(audioProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text('Sesi belum tersedia', style: AppTextStyles.heading),
                const SizedBox(height: 6),
                Text(
                  'Silakan login ulang agar profil dan papan peringkat memuat data akun yang benar.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Ke Halaman Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Text('Profil', style: AppTextStyles.screenTitle),
                    const SizedBox(height: 16),
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 3),
                        color: AppColors.primaryBlueLight,
                      ),
                      child: Center(child: Text(user.initials,
                        style: AppTextStyles.scoreLarge.copyWith(color: AppColors.primaryBlueAccent))),
                    ),
                    const SizedBox(height: 10),
                    Text(user.displayName, style: AppTextStyles.screenTitle),
                    // WhatsApp number display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 14, color: Colors.green.shade300),
                        const SizedBox(width: 4),
                        Text(user.formattedPhone,
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip('🔥 ${user.streak} Hari', AppColors.accentOrangeWarm),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENGATURAN', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryBlue)),
                  const SizedBox(height: 10),
                  _settingTile(Icons.volume_up_rounded, AppStrings.audioSettings,
                    subtitle: audio.sfxEnabled ? 'Aktif' : 'Nonaktif',
                    trailing: Switch(
                      value: audio.sfxEnabled,
                      onChanged: (_) => ref.read(audioProvider.notifier).toggleSfx(),
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _settingTile(Icons.music_note_rounded, AppStrings.musicSettings,
                    subtitle: audio.musicEnabled ? 'Aktif' : 'Nonaktif',
                    trailing: Switch(
                      value: audio.musicEnabled,
                      onChanged: (_) => ref.read(audioProvider.notifier).toggleMusic(),
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('LAINNYA', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryBlue)),
                  const SizedBox(height: 10),
                  _settingTile(Icons.info_outline_rounded, AppStrings.about,
                    subtitle: 'NetLearn v1.0'),
                  _settingTile(
                    Icons.leaderboard_rounded,
                    AppStrings.leaderboard,
                    onTap: () => _showLeaderboard(context, ref),
                  ),
                  _settingTile(
                    Icons.restart_alt_rounded,
                    'Reset Data Belajar',
                    subtitle: 'Kembalikan progress seperti akun baru',
                    onTap: () => _confirmResetLearningData(context, ref),
                  ),
                  _settingTile(
                    Icons.lock_open_rounded,
                    'Buka Semua Menu',
                    subtitle: 'Buka kunci Materi, Simulasi, Test, Progress',
                    onTap: () => _confirmUnlockAllMenus(context, ref),
                  ),
                  _settingTile(Icons.person, 'Profil Author',
                    subtitle: 'Faridatus Shofiyah\nMagister Teknologi Pendidikan\nUniversitas Sebelas Maret'),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      ref.read(audioProvider.notifier).muteAll();
                      context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text(AppStrings.logout, style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: AppTextStyles.pillText.copyWith(color: color)),
  );

  Future<void> _confirmUnlockAllMenus(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buka semua menu?'),
        content: const Text(
          'Semua menu yang terkunci akan dibuka: Materi, Simulasi, Progress, Post-Test, '
          'dan seluruh unit materi. Skor Pre/Post-Test diisi dan badge dibuka.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Buka Semua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(progressProvider.notifier).unlockAllMenus();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua menu berhasil dibuka.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka menu: $e')),
      );
    }
  }

  Future<void> _confirmResetLearningData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset data belajar?'),
        content: const Text(
          'Semua progress materi, skor quiz, badge, XP, dan streak akan dihapus. '
          'Akun dan pengaturan audio tetap tersimpan. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(progressProvider.notifier).resetAllLearningData();
      await ref.read(authProvider.notifier).resetUserLearningProfile();
      ref.read(materialProvider.notifier).resetLearningSession();
      ref.read(quizProvider.notifier).resetQuiz();
      ref.read(simulationProvider.notifier).reset();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belajar berhasil direset.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal reset data: $e')),
      );
    }
  }

  Widget _settingTile(IconData icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  if (subtitle != null) Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing
            else const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaderboard(BuildContext context, WidgetRef ref) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Consumer ensures leaderboard refreshes when current user's progress changes
        // (e.g., after finishing slides / quizzes) while the sheet is open.
        return Consumer(
          builder: (context, ref, _) {
            // Watch progress updates to trigger rebuilds.
            ref.watch(progressProvider);

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.leaderboard, style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('users').limitToLast(100).onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Gagal memuat papan peringkat.'),
                          );
                        }

                        final users = _parseLeaderboardSeeds(snapshot.data?.snapshot.value);
                        if (users.isEmpty) {
                          return const Center(
                            child: Text('Belum ada data papan peringkat.'),
                          );
                        }

                        return FutureBuilder<List<_LeaderboardRow>>(
                          // Recomputed on rebuild (triggered by progressProvider changes).
                          future: _buildLeaderboardRows(users, progressRepo),
                          builder: (context, leaderboardSnapshot) {
                            if (leaderboardSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final entries = leaderboardSnapshot.data ?? const [];
                            if (entries.isEmpty) {
                              return const Center(
                                child: Text('Belum ada data progress untuk ditampilkan.'),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = entries[index];
                                final progressPercent = (row.learningProgress * 100).round();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: index < 3
                                        ? AppColors.primaryBlue.withValues(alpha: 0.08)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '#${index + 1}',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primaryBlueLight,
                                        child: Text(
                                          _initials(row.displayName),
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.primaryBlueAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              row.displayName,
                                              style: AppTextStyles.bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Nilai ${row.finalScore} • Progress $progressPercent%',
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_LeaderboardSeed> _parseLeaderboardSeeds(Object? rawValue) {
    if (rawValue is! Map) return const [];

    final result = <_LeaderboardSeed>[];
    rawValue.forEach((key, value) {
      if (value is! Map) return;

      final map = Map<String, dynamic>.from(value);
      final id = key.toString();
      final displayName = (map['displayName'] as String?)?.trim().isNotEmpty == true
          ? (map['displayName'] as String).trim()
          : id;

      final xp = _asNonNegativeInt(map['xp']);
      final level = _asValidatedLevel(map['level'], xp);
      final streak = _asNonNegativeInt(map['streak']);

      result.add(
        _LeaderboardSeed(
          userId: id,
          displayName: displayName,
          level: level,
          streak: streak,
        ),
      );
    });
    return result;
  }

  Future<List<_LeaderboardRow>> _buildLeaderboardRows(
    List<_LeaderboardSeed> seeds,
    ProgressRepository progressRepo,
  ) async {
    final rows = await Future.wait(
      seeds.map((seed) async {
        final progressList = await progressRepo.getProgress(seed.userId);
        final unitProgress = progressList.where((p) => p.unitId != '__overall__').toList();
        final overall = progressList.cast<ProgressModel?>().firstWhere(
              (p) => p?.unitId == '__overall__',
              orElse: () => null,
            );

        final totalMaterials = unitProgress.fold<int>(0, (sum, p) => sum + p.totalMaterials);
        final doneMaterials = unitProgress.fold<int>(0, (sum, p) => sum + p.materialsCompleted);
        final learningProgress = totalMaterials > 0 ? doneMaterials / totalMaterials : 0.0;

        final unitScores = unitProgress
            .map((p) => p.finalScore ?? p.checkpointAverage)
            .whereType<int>()
            .toList();
        final fallbackScore = unitScores.isEmpty
            ? 0
            : (unitScores.reduce((a, b) => a + b) / unitScores.length).round();

        return _LeaderboardRow(
          displayName: seed.displayName,
          level: seed.level,
          streak: seed.streak,
          finalScore: overall?.finalScore ?? fallbackScore,
          learningProgress: learningProgress,
        );
      }),
    );

    rows.sort((a, b) {
      final scoreCompare = b.finalScore.compareTo(a.finalScore);
      if (scoreCompare != 0) return scoreCompare;

      final progressCompare = b.learningProgress.compareTo(a.learningProgress);
      if (progressCompare != 0) return progressCompare;

      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) return levelCompare;

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return rows;
  }

  int _asNonNegativeInt(dynamic value) {
    final parsed = switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  int _asValidatedLevel(dynamic rawLevel, int xp) {
    final parsed = _asNonNegativeInt(rawLevel);
    final safeLevel = parsed < 1 ? 1 : parsed;
    final derivedLevel = (xp ~/ 100) + 1;
    return derivedLevel > safeLevel ? derivedLevel : safeLevel;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isEmpty) return '?';
    final text = parts.first;
    return text.substring(0, text.length.clamp(0, 2)).toUpperCase();
  }
}

class _LeaderboardSeed {
  final String userId;
  final String displayName;
  final int level;
  final int streak;

  const _LeaderboardSeed({
    required this.userId,
    required this.displayName,
    required this.level,
    required this.streak,
  });
}

class _LeaderboardRow {
  final String displayName;
  final int level;
  final int streak;
  final int finalScore;
  final double learningProgress;

  const _LeaderboardRow({
    required this.displayName,
    required this.level,
    required this.streak,
    required this.finalScore,
    required this.learningProgress,
  });
}
