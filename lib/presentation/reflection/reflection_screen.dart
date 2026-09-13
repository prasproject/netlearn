import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/reflection_model.dart';
import '../../domain/providers/progress_provider.dart';

/// Reflection Screen — Post learning self-reflection form.
/// Accessible from Home and shown right after finishing the Post-Test.
class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  UnderstandingLevel? _selectedLevel;
  final _mostUnderstoodController = TextEditingController();
  final _needsMoreStudyController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final reflection = ref.read(progressProvider).reflection;
    if (reflection != null) {
      _selectedLevel = reflection.understandingLevel;
      _mostUnderstoodController.text = reflection.mostUnderstoodTopic;
      _needsMoreStudyController.text = reflection.needsMoreStudyTopic;
    }
  }

  @override
  void dispose() {
    _mostUnderstoodController.dispose();
    _needsMoreStudyController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedLevel != null &&
      _mostUnderstoodController.text.trim().isNotEmpty &&
      _needsMoreStudyController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    await ref
        .read(progressProvider.notifier)
        .saveReflection(
          ReflectionModel(
            understandingLevel: _selectedLevel!,
            mostUnderstoodTopic: _mostUnderstoodController.text.trim(),
            needsMoreStudyTopic: _needsMoreStudyController.text.trim(),
            submittedAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refleksi berhasil disimpan')));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard().animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 16),
                  _buildUnderstandingQuestion().animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  _buildTextQuestion(
                    number: 2,
                    title: 'Materi apa yang paling Anda pahami?',
                    subtitle: 'Tuliskan materi atau bagian yang paling Anda pahami.',
                    controller: _mostUnderstoodController,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  _buildTextQuestion(
                    number: 3,
                    title: 'Materi apa yang masih perlu Anda pelajari lebih lanjut?',
                    subtitle: 'Tuliskan materi atau bagian yang masih perlu Anda pahami.',
                    controller: _needsMoreStudyController,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'SIMPAN REFLEKSI',
                    icon: Icons.send_rounded,
                    width: double.infinity,
                    onPressed: _isValid ? _submit : null,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.brandGradient,
          stops: AppColors.brandGradientStops,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Refleksi', style: AppTextStyles.screenTitle),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: AppColors.primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yuk, lakukan refleksi!', style: AppTextStyles.heading.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Setelah mempelajari seluruh materi, luangkan waktu untuk merefleksikan pemahaman dan pengalaman belajarmu.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required int number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.pillText.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
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

  Widget _buildUnderstandingQuestion() {
    final options = [
      (
        UnderstandingLevel.sangatPaham,
        '⭐️',
        AppColors.secondaryGreen,
        AppColors.secondaryGreenSurface,
      ),
      (UnderstandingLevel.paham, '🙂', AppColors.primaryBlue, AppColors.primaryBlueSurface),
      (UnderstandingLevel.cukupPaham, '😐', AppColors.accentOrange, AppColors.accentOrangeSurface),
      (UnderstandingLevel.belumPaham, '☹️', AppColors.error, const Color(0xFFFFEBEE)),
    ];

    return _sectionCard(
      number: 1,
      title: 'Seberapa paham Anda terhadap materi ini?',
      subtitle: 'Pilih salah satu sesuai dengan pemahaman Anda.',
      child: Row(
        children: options.map((option) {
          final (level, emoji, color, surface) = option;
          final isSelected = _selectedLevel == level;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        level.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: isSelected ? color : AppColors.textDisabled,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextQuestion({
    required int number,
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return _sectionCard(
      number: number,
      title: title,
      subtitle: subtitle,
      child: TextField(
        controller: controller,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Tulis jawaban Anda di sini...',
          hintStyle: AppTextStyles.bodySmall,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }
}
