import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/auth_provider.dart';
import 'onboarding_illustrations.dart';

/// Storage key marking that a user has finished the welcome tour.
String onboardingSeenKey(String userId) => 'onboarding_seen_$userId';

class _Page {
  const _Page({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.bullets,
    required this.color,
    required this.accent,
    required this.scene,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<(IconData, String)> bullets;
  final Color color;
  final Color accent;
  final Widget scene;
}

/// Full-screen welcome tour shown right after a new account is created.
///
/// Replaces the old flow, where a brand-new user landed straight on the home
/// screen with only a blurred spotlight and a one-line caption per menu.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _storage = GetStorage();
  int _index = 0;

  static const _pages = <_Page>[
    _Page(
      eyebrow: 'SELAMAT DATANG',
      title: 'Halo, selamat datang\ndi NetLearn!',
      description:
          'Aplikasi belajar jaringan komputer yang bisa kamu pakai sambil mencoba langsung, bukan cuma membaca.',
      bullets: [
        (Icons.school_rounded, 'Materi disusun bertahap dari dasar'),
        (Icons.touch_app_rounded, 'Banyak bagian bisa kamu klik & coba'),
      ],
      color: AppColors.primaryBlue,
      accent: AppColors.primaryBlueSurface,
      scene: WelcomeScene(),
    ),
    _Page(
      eyebrow: 'ALUR BELAJAR',
      title: 'Ikuti 4 langkah\nini berurutan',
      description:
          'Mulai dari Pre-Test untuk mengukur kemampuan awal, lalu belajar materi, latihan, dan tutup dengan Post-Test.',
      bullets: [
        (Icons.lock_open_rounded, 'Menu berikutnya terbuka setelah langkah sebelumnya selesai'),
        (Icons.insights_rounded, 'Selisih Pre-Test & Post-Test jadi nilai peningkatanmu'),
      ],
      color: AppColors.accentOrange,
      accent: AppColors.accentOrangeSurface,
      scene: JourneyScene(),
    ),
    _Page(
      eyebrow: 'MATERI',
      title: 'Baca materi\nslide demi slide',
      description:
          'Tiap unit berisi beberapa slide bergambar. Tekan "Lanjut" untuk pindah slide — progresmu tersimpan otomatis.',
      bullets: [
        (Icons.menu_book_rounded, '5 unit materi, dari dasar sampai keamanan jaringan'),
        (Icons.edit_note_rounded, 'Selesai satu unit langsung lanjut ke latihan soal'),
      ],
      color: AppColors.primaryBlueLight,
      accent: AppColors.primaryBlueSurface,
      scene: MaterialScene(),
    ),
    _Page(
      eyebrow: 'SIMULASI',
      title: 'Coba kirim paket\ndi jaringanmu sendiri',
      description:
          'Susun perangkat, pilih jalur, lalu kirim paket data dan lihat perjalanannya bergerak antar perangkat.',
      bullets: [
        (Icons.hub_rounded, 'Geser perangkat dan hubungkan dengan kabel'),
        (Icons.play_circle_fill_rounded, 'Tombol "Kirim Paket" memutar animasi rutenya'),
      ],
      color: AppColors.secondaryGreen,
      accent: AppColors.secondaryGreenSurface,
      scene: SimulationScene(),
    ),
    _Page(
      eyebrow: 'PENGHARGAAN',
      title: 'Kumpulkan XP,\nbadge, dan sertifikat',
      description:
          'Setiap slide yang kamu selesaikan dan setiap kuis yang kamu kerjakan menambah XP, menaikkan level, dan membuka badge.',
      bullets: [
        (Icons.local_fire_department_rounded, 'Belajar tiap hari untuk menjaga streak'),
        (Icons.workspace_premium_rounded, 'Selesaikan Post-Test untuk mendapat sertifikat'),
      ],
      color: AppColors.gold,
      accent: AppColors.goldSurface,
      scene: RewardScene(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      ref.read(audioProvider.notifier).playSfx(SoundEffect.slideNext);
      _finish();
      return;
    }
    // No sound here: `onPageChanged` plays it once the page actually moves.
    // Playing it in both places made one tap sound like two.
    _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId != null) {
      await _storage.write(onboardingSeenKey(userId), true);
    }
    if (!mounted) return;
    // The menu spotlight tour picks up from here on the home screen.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(page),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  // Single source of the page-turn sound, so tapping "Lanjut"
                  // and swiping both make exactly one sound.
                  ref.read(audioProvider.notifier).playSfx(SoundEffect.slideNext);
                },
                itemBuilder: (context, i) => _pageBody(_pages[i], i),
              ),
            ),
            _bottomBar(page),
          ],
        ),
      ),
    );
  }

  Widget _topBar(_Page page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _index == 0 ? 0 : 1,
            child: IconButton(
              onPressed: _index == 0 ? null : _back,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Kembali',
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _finish,
            child: Text(
              _isLast ? 'Tutup' : 'Lewati',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBody(_Page page, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: page.scene),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: page.accent, borderRadius: BorderRadius.circular(99)),
            child: Text(page.eyebrow, style: AppTextStyles.eyebrow.copyWith(color: page.color)),
          ).animate(key: ValueKey('eyebrow$index')).fadeIn(duration: 300.ms).slideY(begin: 0.4),
          const SizedBox(height: 10),
          Text(
                page.title,
                style: AppTextStyles.splashTitle.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              )
              .animate(key: ValueKey('title$index'))
              .fadeIn(delay: 80.ms, duration: 320.ms)
              .slideY(begin: 0.3),
          const SizedBox(height: 10),
          Text(
            page.description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
          ).animate(key: ValueKey('desc$index')).fadeIn(delay: 160.ms, duration: 320.ms),
          const SizedBox(height: 16),
          for (var i = 0; i < page.bullets.length; i++)
            Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: page.accent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(page.bullets[i].$1, size: 16, color: page.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          page.bullets[i].$2,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(key: ValueKey('bullet$index$i'))
                .fadeIn(delay: (220 + i * 90).ms, duration: 300.ms)
                .slideX(begin: 0.12),
        ],
      ),
    );
  }

  Widget _bottomBar(_Page page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? page.color : AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GradientButton(
            text: _isLast ? 'Mulai Belajar' : 'Lanjut',
            icon: _isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
            backgroundColor: page.color,
            shadowColor: Color.lerp(page.color, Colors.black, 0.25)!,
            width: double.infinity,
            onPressed: _next,
          ),
          const SizedBox(height: 6),
          Text(
            'Langkah ${_index + 1} dari ${_pages.length}',
            style: AppTextStyles.labelTiny.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
