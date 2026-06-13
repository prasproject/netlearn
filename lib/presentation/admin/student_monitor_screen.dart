import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/progress_repository.dart';
import '../../domain/providers/repository_providers.dart';

class StudentMonitorScreen extends ConsumerStatefulWidget {
  const StudentMonitorScreen({super.key});

  @override
  ConsumerState<StudentMonitorScreen> createState() => _StudentMonitorScreenState();
}

class _StudentMonitorScreenState extends ConsumerState<StudentMonitorScreen> {
  bool _loading = true;
  List<UserModel> _students = [];
  List<_StudentRankEntry> _rankedStudents = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<UserModel> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final keyword = _searchQuery.trim().toLowerCase();
    return _students.where((student) {
      return student.displayName.toLowerCase().contains(keyword) ||
          student.id.toLowerCase().contains(keyword) ||
          student.phoneNumber.toLowerCase().contains(keyword);
    }).toList();
  }

  List<_StudentRankEntry> get _filteredRankedStudents {
    if (_searchQuery.trim().isEmpty) return _rankedStudents;
    final keyword = _searchQuery.trim().toLowerCase();
    return _rankedStudents.where((entry) {
      final student = entry.user;
      return student.displayName.toLowerCase().contains(keyword) ||
          student.id.toLowerCase().contains(keyword) ||
          student.phoneNumber.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final users = await ref.read(authRepositoryProvider).getAllUsers();
    final students = users.where((u) => u.role != 'admin').toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final progressRepo = ref.read(progressRepositoryProvider);
    final ranked = await Future.wait(
      students.map((student) => _buildRankEntry(student, progressRepo)),
    );
    ranked.sort((a, b) {
      final scoreCompare = b.finalScore.compareTo(a.finalScore);
      if (scoreCompare != 0) return scoreCompare;

      final progressCompare = b.learningProgress.compareTo(a.learningProgress);
      if (progressCompare != 0) return progressCompare;

      return a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase());
    });
    if (!mounted) return;
    setState(() {
      _students = students;
      _rankedStudents = ranked;
      _loading = false;
    });
  }

  Future<_StudentRankEntry> _buildRankEntry(
    UserModel student,
    ProgressRepository progressRepo,
  ) async {
    final progressList = await progressRepo.getProgress(student.id);
    final unitProgress = progressList.where((p) => p.unitId != '__overall__').toList();
    final overall = progressList.cast<ProgressModel?>().firstWhere(
          (p) => p?.unitId == '__overall__',
          orElse: () => null,
        );

    final totalMaterials = unitProgress.fold<int>(0, (sum, p) => sum + p.totalMaterials);
    final completedMaterials = unitProgress.fold<int>(
      0,
      (sum, p) => sum + p.materialsCompleted,
    );
    final learningProgress = totalMaterials > 0 ? completedMaterials / totalMaterials : 0.0;

    final unitScores = unitProgress
        .map((p) => p.finalScore ?? p.checkpointAverage)
        .whereType<int>()
        .toList();
    final fallbackScore = unitScores.isEmpty
        ? 0
        : (unitScores.reduce((a, b) => a + b) / unitScores.length).round();

    return _StudentRankEntry(
      user: student,
      finalScore: overall?.finalScore ?? fallbackScore,
      learningProgress: learningProgress,
    );
  }

  Future<void> _showUserForm({UserModel? user}) async {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final usernameController = TextEditingController(text: user?.id ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEdit ? 'Edit User' : 'Tambah User',
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameController,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Username wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Nomor WhatsApp wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Password baru (opsional)' : 'Password',
                    ),
                    validator: (value) {
                      if (!isEdit && (value == null || value.trim().isEmpty)) {
                        return 'Password wajib diisi';
                      }
                      if (value != null && value.isNotEmpty && value.length < 4) {
                        return 'Minimal 4 karakter';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  if (isEdit) {
                    final updatedUser = user.copyWith(
                      displayName: nameController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      password: passwordController.text.trim().isEmpty
                          ? user.password
                          : passwordController.text.trim(),
                      lastActive: DateTime.now(),
                    );
                    await ref.read(authRepositoryProvider).updateUser(updatedUser);
                  } else {
                    await ref.read(authRepositoryProvider).createUser(
                          name: nameController.text.trim(),
                          username: usernameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    if (saved == true) {
      await _loadStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'User berhasil diperbarui' : 'User berhasil ditambahkan')),
      );
    }
  }

  Future<void> _confirmDelete(UserModel user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus User?'),
        content: Text('User "${user.displayName}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteUser(user.id);
      await _loadStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _showUserAchievement(UserModel user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return FutureBuilder<_UserAchievementData>(
          future: _loadUserAchievementData(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('Gagal memuat capaian user')),
              );
            }
            final data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text('Username: ${user.id}', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _achievementChip('Streak', '${user.streak}'),
                      _achievementChip('Unit selesai', '${data.completedUnits}/${data.totalUnits}'),
                      _achievementChip('Rata skor akhir', '${data.averageFinalScore}'),
                      _achievementChip('Pre/Post', '${data.pretestScore}/${data.posttestScore}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Achievement Unlocked: ${data.unlockedAchievements}', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text(
                    data.unlockedAchievementNames.isEmpty
                        ? 'Belum ada achievement yang terbuka.'
                        : data.unlockedAchievementNames.join(', '),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<_UserAchievementData> _loadUserAchievementData(String userId) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    final progressList = await progressRepo.getProgress(userId);
    final achievements = await progressRepo.getAchievements(userId);

    final unitProgress = progressList.where((p) => p.unitId != '__overall__').toList();
    final overall = progressList.cast<ProgressModel?>().firstWhere(
          (p) => p?.unitId == '__overall__',
          orElse: () => null,
        );
    final completedUnits = unitProgress.where((p) => p.isCompleted).length;
    final finishedScores = unitProgress
        .map((p) => p.finalScore ?? p.checkpointAverage)
        .whereType<int>()
        .toList();
    final averageFinalScore = finishedScores.isEmpty
        ? 0
        : (finishedScores.reduce((a, b) => a + b) / finishedScores.length).round();
    final unlocked = achievements.where((a) => a.isUnlocked).toList();

    return _UserAchievementData(
      completedUnits: completedUnits,
      totalUnits: unitProgress.length,
      averageFinalScore: averageFinalScore,
      pretestScore: overall?.pretestScore ?? 0,
      posttestScore: overall?.finalScore ?? 0,
      unlockedAchievements: unlocked.length,
      unlockedAchievementNames: unlocked.map((e) => e.name).toList(),
    );
  }

  Widget _achievementChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pantau Siswa', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cari user (nama, username, WA)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _showUserForm(),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User Terdaftar',
                    style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_filteredStudents.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('Tidak ada user yang cocok dengan pencarian'),
                      ),
                    ),
                  ..._filteredStudents.map(
                    (student) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          child: Text(
                            student.initials.isEmpty ? '?' : student.initials.substring(0, 1),
                            style: const TextStyle(color: AppColors.primaryBlue),
                          ),
                        ),
                        title: Text(student.displayName, style: AppTextStyles.heading),
                        subtitle: Text(
                          'Username: ${student.id} • WA: ${student.phoneNumber}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'achievement') {
                              _showUserAchievement(student);
                              return;
                            }
                            if (value == 'edit') {
                              _showUserForm(user: student);
                              return;
                            }
                            if (value == 'delete') {
                              _confirmDelete(student);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'achievement',
                              child: Text('Lihat capaian'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit user'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus user'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Leaderboard (Berdasarkan Nilai & Progress)',
                    style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  ..._filteredRankedStudents.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final row = entry.value;
                    final user = row.user;
                    final progressPercent = (row.learningProgress * 100).round();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank <= 3
                              ? AppColors.accentOrange
                              : AppColors.primaryBlueLight,
                          child: Text('$rank', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(user.displayName, style: AppTextStyles.heading),
                        subtitle: Text(
                          'Nilai ${row.finalScore} • Progress $progressPercent%',
                        ),
                        trailing: Text(
                          '${row.finalScore}',
                          style: AppTextStyles.heading.copyWith(color: AppColors.secondaryGreen),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _UserAchievementData {
  final int completedUnits;
  final int totalUnits;
  final int averageFinalScore;
  final int pretestScore;
  final int posttestScore;
  final int unlockedAchievements;
  final List<String> unlockedAchievementNames;

  const _UserAchievementData({
    required this.completedUnits,
    required this.totalUnits,
    required this.averageFinalScore,
    required this.pretestScore,
    required this.posttestScore,
    required this.unlockedAchievements,
    required this.unlockedAchievementNames,
  });
}

class _StudentRankEntry {
  final UserModel user;
  final int finalScore;
  final double learningProgress;

  const _StudentRankEntry({
    required this.user,
    required this.finalScore,
    required this.learningProgress,
  });
}
