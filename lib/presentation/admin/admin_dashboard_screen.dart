import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/progress_model.dart';
import '../../domain/providers/repository_providers.dart';
import '../../domain/services/ngain_calculator.dart';
import '../../domain/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late final Future<_AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<_AdminStats> _loadStats() async {
    final users = await ref.read(authRepositoryProvider).getAllUsers();
    final students = users.where((u) => u.role != 'admin').toList();

    final progressRepo = ref.read(progressRepositoryProvider);
    const overallUnitId = '__overall__';

    double nGainSum = 0.0;
    int nGainCount = 0;

    for (final student in students) {
      final all = await progressRepo.getProgress(student.id);
      final overall = all.cast<ProgressModel?>().firstWhere(
            (p) => p?.unitId == overallUnitId,
            orElse: () => null,
          );

      final int? pre = overall?.pretestScore;
      final int? post = overall?.finalScore;
      if (pre == null || post == null) continue;

      nGainSum += NGainCalculator.calculate(preScore: pre, postScore: post);
      nGainCount++;
    }

    final avgNGain = nGainCount == 0 ? 0.0 : (nGainSum / nGainCount);
    return _AdminStats(totalStudents: students.length, avgNGain: avgNGain);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final adminName = authState.user?.displayName ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $adminName! 👋', style: AppTextStyles.scoreLarge.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Selamat datang di Panel Manajemen NetLearn.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            
            FutureBuilder<_AdminStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data;
                final totalStudents = stats?.totalStudents;
                final avgNGain = stats?.avgNGain;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Siswa',
                        value: isLoading ? '—' : '${totalStudents ?? 0}',
                        icon: Icons.people,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Rata-rata N-Gain',
                        value: isLoading ? '—' : (avgNGain ?? 0).toStringAsFixed(2),
                        icon: Icons.trending_up,
                        color: AppColors.secondaryGreen,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            Text('Menu Utama', style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            
            // Menu Cards
            _MenuCard(
              title: 'Kelola Materi (CMS)',
              description: 'Tambah, edit, dan atur visibilitas materi & kuis.',
              icon: Icons.book,
              color: AppColors.primaryBlue,
              onTap: () => context.push('/admin/materials'),
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Pantau Siswa',
              description: 'Lihat daftar siswa, progress, dan nilai evaluasi.',
              icon: Icons.analytics,
              color: AppColors.accentOrange,
              onTap: () => context.push('/admin/students'),
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Reporting Gabungan',
              description: 'Laporan user + pretest, posttest, progress, dan export.',
              icon: Icons.assessment,
              color: AppColors.secondaryGreen,
              onTap: () => context.push('/admin/reporting'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.scoreLarge.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _AdminStats {
  final int totalStudents;
  final double avgNGain;

  const _AdminStats({
    required this.totalStudents,
    required this.avgNGain,
  });
}
