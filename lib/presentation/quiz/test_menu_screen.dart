import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/header_back_button.dart';
import '../../domain/providers/progress_provider.dart';

class TestMenuScreen extends ConsumerWidget {
  const TestMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final hasPretestScore = progress.overallPretestScore > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.accentOrange),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    const HeaderBackButton(),
                    const SizedBox(width: 10),
                    Text('Test', style: AppTextStyles.screenTitle),
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
                  Text(
                    'PILIH JENIS TEST',
                    style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentOrangeDark),
                  ),
                  const SizedBox(height: 10),
                  _menuCard(
                    context,
                    title: 'Pre-Test',
                    subtitle: 'Cek kemampuan awal sebelum belajar',
                    color: AppColors.accentOrange,
                    icon: Icons.fact_check_rounded,
                    onTap: () => context.push('/pretest'),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
                  const SizedBox(height: 10),
                  _menuCard(
                    context,
                    title: 'Post-Test',
                    subtitle: hasPretestScore ? 'Ukur peningkatan setelah belajar' : 'Terkunci — kerjakan Pre-Test dulu',
                    color: AppColors.secondaryGreen,
                    icon: Icons.task_alt_rounded,
                    enabled: hasPretestScore,
                    onTap: () => context.push('/posttest'),
                  ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (!enabled)
              Icon(Icons.lock_rounded, color: Colors.grey.shade400)
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

