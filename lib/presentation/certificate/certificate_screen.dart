import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/file_export.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/seed/seed_data.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/services/certificate_generator.dart';

/// Certificate Screen — Blue gradient with trophy, stats, PDF export.
class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  bool _isGenerating = false;
  String? _savedPath;

  Future<void> _generatePdf() async {
    final user = ref.read(authProvider).user ?? SeedData.demoUser;
    final progress = ref.read(progressProvider);

    setState(() => _isGenerating = true);
    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);

    try {
      final path = await CertificateGenerator.generate(
        studentName: user.displayName,
        finalScore: progress.overallPosttestScore,
        nGain: progress.nGain,
        totalXp: user.xp,
        pretestScore: progress.overallPretestScore,
        posttestScore: progress.overallPosttestScore,
      );

      setState(() {
        _isGenerating = false;
        _savedPath = path;
      });

      ref.read(audioProvider.notifier).playSfx(SoundEffect.badgeUnlock);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWebExport
                  ? '✅ Sertifikat PDF berhasil diunduh!'
                  : '✅ Sertifikat PDF berhasil disimpan!',
            ),
            backgroundColor: AppColors.secondaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: isWebExport
                ? null
                : SnackBarAction(
                    label: 'Buka',
                    textColor: Colors.white,
                    onPressed: () => openSavedFile(path),
                  ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user ?? SeedData.demoUser;
    final progress = ref.watch(progressProvider);

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Color(0xFF0A3575)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: -60, right: -60, child: _bgCircle(200)),
              Positioned(bottom: -30, left: -30, child: _bgCircle(120)),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Badge
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 4),
                          color: AppColors.goldSurface,
                        ),
                        child: const Icon(Icons.star_rounded, size: 44, color: AppColors.gold),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(AppStrings.congratulations,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.certTitle,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 8),
                      Text(user.displayName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.certName,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 8),
                      Text('${AppStrings.certificateCourse}\n${AppStrings.certificateSchool}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.certSub,
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statBox('${progress.overallPosttestScore}', 'Skor Akhir'),
                          const SizedBox(width: 10),
                          _statBox(progress.nGain.toStringAsFixed(2), 'N-Gain'),
                          const SizedBox(width: 10),
                          _statBox('${user.xp}', 'Total XP'),
                        ],
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 30),
                      // Buttons
                      Row(
                        children: [
                          // Save PDF button
                          Expanded(
                            child: GestureDetector(
                              onTap: _isGenerating ? null : _generatePdf,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _savedPath != null
                                      ? AppColors.secondaryGreen.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _savedPath != null
                                        ? AppColors.secondaryGreenAccent
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isGenerating)
                                      const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white,
                                        ),
                                      )
                                    else
                                      Icon(
                                        _savedPath != null ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
                                        size: 16, color: Colors.white,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isGenerating ? 'Membuat...'
                                          : _savedPath != null ? 'Tersimpan ✓' : 'Simpan PDF',
                                      style: AppTextStyles.buttonPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Open PDF button (visible only after saved, mobile/desktop)
                          if (_savedPath != null && !isWebExport)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => openSavedFile(_savedPath!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                                  ),
                                  child: Text('Buka PDF', textAlign: TextAlign.center,
                                    style: AppTextStyles.buttonPrimary),
                                ),
                              ),
                            ),
                          if (_savedPath != null) const SizedBox(width: 10),
                          // Home button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.go('/home'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold, borderRadius: BorderRadius.circular(12),
                                  boxShadow: [const BoxShadow(color: AppColors.goldDark, offset: Offset(0, 3))],
                                ),
                                child: Text('Beranda', textAlign: TextAlign.center,
                                  style: AppTextStyles.buttonPrimary.copyWith(color: AppColors.textPrimary)),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statValue.copyWith(fontSize: 18)),
          Text(label, style: AppTextStyles.statLabel.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _bgCircle(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
  );
}
