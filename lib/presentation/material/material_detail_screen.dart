import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/material_model.dart';
import '../../data/models/progress_model.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';

/// Material Detail Screen — Slide-based learning content view.
class MaterialDetailScreen extends ConsumerWidget {
  final String unitId;
  const MaterialDetailScreen({super.key, required this.unitId});

  bool _isUnitLocked({
    required String unitId,
    required List<MaterialModel> units,
    required List<ProgressModel> progress,
  }) {
    final ordered = List<MaterialModel>.from(units)
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        if (o != 0) return o;
        return a.unitNumber.compareTo(b.unitNumber);
      });
    final idx = ordered.indexWhere((u) => u.id == unitId);
    if (idx <= 0) return false;
    final prev = ordered[idx - 1];
    final prevP = progress.where((p) => p.unitId == prev.id).cast<ProgressModel?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        ) ??
        ProgressModel(unitId: prev.id, totalMaterials: prev.totalSlides);
    // Unit tidak boleh terkunci karena checkpoint.
    // Cukup selesaikan materi unit sebelumnya untuk membuka unit berikutnya.
    return !prevP.isCompleted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matState = ref.watch(materialProvider);
    final progress = ref.watch(progressProvider);
    final unit = matState.materials.firstWhere((m) => m.id == unitId, orElse: () => matState.materials.first);
    final locked = _isUnitLocked(unitId: unit.id, units: matState.materials, progress: progress.unitProgress);
    if (locked) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlueSurface,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Unit masih terkunci', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  'Selesaikan Unit sebelumnya terlebih dahulu untuk membuka “${unit.title}”.',
                  style: AppTextStyles.paragraph.copyWith(fontSize: 16, height: 1.6),
                ),
                const Spacer(),
                GradientButton(
                  text: 'Kembali ke daftar materi',
                  onPressed: () => context.pop(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final slideIndex = matState.currentSlideIndex.clamp(0, unit.slides.length - 1);
    final slide = unit.slides[slideIndex];
    final isBookmarked = ref.read(materialProvider.notifier).isBookmarked(unitId, slideIndex);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            unit.title,
                            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${slideIndex + 1} / ${unit.totalSlides}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref.read(materialProvider.notifier).toggleBookmark(unitId, slideIndex),
                          child: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white70, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Slide dots
                    Row(
                      children: List.generate(unit.totalSlides, (i) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: i < slideIndex ? AppColors.primaryBlueAccent
                                  : i == slideIndex ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Illustration area
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      decoration: const BoxDecoration(color: AppColors.primaryBlueSurface),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _decodeBase64Image(slide.imageBase64) != null
                            ? _Base64SlideImage(
                                bytes: _decodeBase64Image(slide.imageBase64)!,
                              )
                            : Padding(
                                padding: const EdgeInsets.all(10),
                                child: _MaterialSlideImage(
                                  unitNumber: unit.unitNumber,
                                  slideNumber: slideIndex + 1,
                                ),
                              ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  // Eyebrow
                  Text(
                    'KONSEP DASAR',
                    style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryBlue, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(slide.title, style: AppTextStyles.heading.copyWith(fontSize: 22))
                      .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  // Content
                  Text(
                    slide.content,
                    style: AppTextStyles.paragraph.copyWith(fontSize: 17, height: 1.75),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  // Keywords chips
                  if (slide.keywords.isNotEmpty)
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: slide.keywords.map((k) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueSurface,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          k,
                          style: AppTextStyles.chip.copyWith(color: AppColors.primaryBlue, fontSize: 13),
                        ),
                      )).toList(),
                    ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
          // Bottom nav buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Kembali',
                    backgroundColor: AppColors.primaryBlue,
                    shadowColor: AppColors.primaryBlueDark,
                    onPressed: () {
                      ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                      ref.read(audioProvider.notifier).stopNarration();
                      if (slideIndex > 0) {
                        ref.read(materialProvider.notifier).previousSlide();
                      } else {
                        context.pop();
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    text: slideIndex < unit.totalSlides - 1 ? 'Lanjut' : 'Selesai',
                    backgroundColor: AppColors.accentOrange,
                    shadowColor: AppColors.accentOrangeDark,
                    onPressed: () {
                      ref.read(audioProvider.notifier).playSfx(SoundEffect.slideNext);
                      ref.read(audioProvider.notifier).stopNarration();
                      if (slideIndex < unit.totalSlides - 1) {
                        ref.read(progressProvider.notifier).completeMaterial(unitId);
                        ref.read(materialProvider.notifier).nextSlide();
                      } else {
                        ref.read(progressProvider.notifier).completeMaterial(unitId);
                        // Selesai materi: kembali ke daftar materi (checkpoint opsional).
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.slideNext);
                        context.pop();
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeBase64Image(String? rawBase64) {
    if (rawBase64 == null || rawBase64.trim().isEmpty) return null;
    try {
      final trimmed = rawBase64.trim();
      final payload = trimmed.contains(',')
          ? trimmed.split(',').last
          : trimmed;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class _Base64SlideImage extends StatelessWidget {
  final Uint8List bytes;

  const _Base64SlideImage({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(bytes, fit: BoxFit.contain);
  }
}

class _MaterialSlideImage extends StatelessWidget {
  final int unitNumber;
  final int slideNumber;

  const _MaterialSlideImage({
    required this.unitNumber,
    required this.slideNumber,
  });

  Future<String> _resolveImageAsset() async {
    final base = 'assets/images/materi_${unitNumber}_$slideNumber';
    final candidates = [
      '$base.png',
      '$base.jpg',
      '$base.jpeg',
      '$base.webp',
      'assets/images/material_placeholder.png',
    ];

    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        return path;
      } catch (_) {
        // Try next candidate.
      }
    }

    return 'assets/images/material_placeholder.png';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveImageAsset(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return Image.asset(
          snapshot.data ?? 'assets/images/material_placeholder.png',
          fit: BoxFit.contain,
        );
      },
    );
  }
}
