import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/header_back_button.dart';

/// Capaian Screen — Menampilkan Capaian Pembelajaran dan Tujuan Pembelajaran.
class CapaianScreen extends StatelessWidget {
  const CapaianScreen({super.key});

  static const _tujuanItems = [
    'Menjelaskan perbedaan jaringan lokal dan internet serta jenis konektivitas kabel dan nirkabel.',
    'Menjelaskan teknologi komunikasi data melalui perangkat seluler.',
    'Menjelaskan pentingnya keamanan data pribadi dan menerapkan enkripsi untuk melindungi dokumen.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.progressTeal),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeaderBackButton(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kompetensi Pembelajaran', style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            'Kompetensi & tujuan pembelajaran',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
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
                  _sectionCard(
                    title: 'Capaian Pembelajaran (CP)',
                    icon: Icons.flag_rounded,
                    child: Text(
                      'Memahami konsep jaringan lokal dan internet, teknologi komunikasi data, '
                      'konektivitas kabel dan nirkabel, serta penerapan enkripsi untuk menjaga '
                      'keamanan data saat terhubung ke jaringan.',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                    ),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Tujuan Pembelajaran',
                    icon: Icons.track_changes_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peserta didik mampu:',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_tujuanItems.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < _tujuanItems.length - 1 ? 10 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.progressTealSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.progressTeal,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _tujuanItems[i],
                                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressTeal.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.progressTealSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.progressTeal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.progressTeal,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
