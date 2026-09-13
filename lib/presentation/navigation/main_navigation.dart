import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_welcome_kit/flutter_welcome_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/providers/audio_provider.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/tutorial_provider.dart';
import '../../domain/providers/material_provider.dart' as mat;
import '../../domain/providers/progress_provider.dart';
import '../home/home_screen.dart';
import '../material/material_list_screen.dart';
import '../simulation/simulation_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';

/// Main navigation shell with bottom nav bar
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final _storage = GetStorage();
  TourController? _tourController;
  ProviderSubscription<int>? _tutorialTriggerSub;
  ProviderSubscription<mat.MaterialState>? _materialSyncSub;

  final _homeKey = GlobalKey();
  final _materialKey = GlobalKey();
  final _simulationKey = GlobalKey();
  final _progressKey = GlobalKey();
  final _profileKey = GlobalKey();

  final _screens = const [
    HomeScreen(),
    MaterialListScreen(),
    SimulationScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // On Flutter Web, refresh can land directly on `/home` and bypass `/splash`.
      // Ensure session restoration happens here too.
      await ref.read(authProvider.notifier).initializeSession();
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn) {
        if (mounted) {
          // If session can't be restored, return to login instead of showing demo data.
          // ignore: use_build_context_synchronously
          context.go('/login');
        }
        return;
      }
      _syncProgressWithMaterials();
      _startTutorialIfNeeded();
    });

    _tutorialTriggerSub = ref.listenManual<int>(tutorialTriggerProvider, (prev, next) {
      if (prev == next) return;
      _startTutorialIfNeeded(force: true);
    });

    _materialSyncSub = ref.listenManual<mat.MaterialState>(mat.materialProvider, (prev, next) {
      if (next.materials.isEmpty) return;
      ref.read(progressProvider.notifier).syncAllMaterialTotals(next.materials);
    });
  }

  void _syncProgressWithMaterials() {
    final materials = ref.read(mat.materialProvider).materials;
    if (materials.isEmpty) return;
    ref.read(progressProvider.notifier).syncAllMaterialTotals(materials);
  }

  @override
  void dispose() {
    _tourController?.end();
    _tutorialTriggerSub?.close();
    _materialSyncSub?.close();
    super.dispose();
  }

  void _startTutorialIfNeeded({bool force = false}) {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;
    if (userId == null) {
      return;
    }

    if (!force) {
      if (!authState.isNewUser || authState.user?.role == 'admin') {
        return;
      }

      final hasSeenTutorial = _storage.read('main_menu_tutorial_seen_$userId') == true;
      if (hasSeenTutorial) {
        ref.read(authProvider.notifier).markNewUserTutorialSeen();
        return;
      }
    }

    _tourController?.end();
    _tourController = TourController(
      context: context,
      steps: [
        TourStep(
          key: _homeKey,
          title: '1/5 · Beranda',
          description:
              'Titik awalmu. Di sini ada ringkasan progres, streak harian, '
              'dan tombol menuju langkah belajar berikutnya. Kalau bingung '
              'harus mulai dari mana, kembalilah ke sini.',
          icon: Icons.home_rounded,
          backgroundColor: AppColors.primaryBlue,
        ),
        TourStep(
          key: _materialKey,
          title: '2/5 · Materi',
          description:
              'Berisi 5 unit materi bergambar. Baca slide-nya sampai habis — '
              'progres tiap slide tersimpan otomatis, dan setelah satu unit '
              'selesai kamu langsung diarahkan ke latihan soal.',
          icon: Icons.menu_book_rounded,
          backgroundColor: AppColors.secondaryGreen,
        ),
        TourStep(
          key: _simulationKey,
          title: '3/5 · Simulasi',
          description:
              'Tempat mencoba langsung: susun perangkat, pilih jalur, lalu '
              'tekan "Kirim Paket" untuk melihat data berjalan antar '
              'perangkat. Tombol info di layar itu berisi tutorialnya.',
          icon: Icons.hub_rounded,
          backgroundColor: AppColors.accentOrange,
        ),
        TourStep(
          key: _progressKey,
          title: '4/5 · Progress',
          description:
              'Rapor belajarmu: nilai Pre-Test & Post-Test, peningkatan '
              '(N-Gain), badge yang sudah terbuka, dan sertifikat setelah '
              'semua langkah selesai.',
          icon: Icons.bar_chart_rounded,
          backgroundColor: AppColors.purple,
        ),
        TourStep(
          key: _profileKey,
          title: '5/5 · Profil',
          description:
              'Atur suara dan musik, lihat XP serta level, dan buka panduan '
              'ini lagi kapan saja lewat tombol tanda tanya di Beranda. '
              'Selamat belajar!',
          icon: Icons.person_rounded,
          backgroundColor: AppColors.primaryBlueLight,
          isLast: true,
          buttonLabel: 'Mulai Belajar',
        ),
      ],
      startDelay: const Duration(milliseconds: 250),
      onComplete: () async {
        await _storage.write('main_menu_tutorial_seen_$userId', true);
        if (!mounted) return;
        ref.read(authProvider.notifier).markNewUserTutorialSeen();
      },
      onSkip: () async {
        await _storage.write('main_menu_tutorial_seen_$userId', true);
        if (!mounted) return;
        ref.read(authProvider.notifier).markNewUserTutorialSeen();
      },
    );
    _tourController!.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadows.overlay),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  0,
                  Icons.home_rounded,
                  'Beranda',
                  navKey: _homeKey,
                  color: AppColors.primaryBlue,
                ),
                _navItem(
                  1,
                  Icons.menu_book_rounded,
                  'Materi',
                  navKey: _materialKey,
                  color: AppColors.secondaryGreen,
                ),
                _navItem(
                  2,
                  Icons.hub_rounded,
                  'Simulasi',
                  navKey: _simulationKey,
                  color: AppColors.accentOrange,
                ),
                _navItem(
                  3,
                  Icons.bar_chart_rounded,
                  'Progress',
                  navKey: _progressKey,
                  color: AppColors.purple,
                ),
                _navItem(
                  4,
                  Icons.person_rounded,
                  'Profil',
                  navKey: _profileKey,
                  color: AppColors.primaryBlueLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom nav item: the active one grows into a coloured pill with its label,
  /// the others stay as quiet icons. Replaces the old static icon + dot, which
  /// gave almost no feedback about where you were.
  Widget _navItem(
    int index,
    IconData icon,
    String label, {
    required GlobalKey navKey,
    required Color color,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: Pressable(
        key: navKey,
        scale: 0.92,
        onTap: () {
          if (isActive) return;
          setState(() => _currentIndex = index);
          ref.read(audioProvider.notifier).playSfx(SoundEffect.navigation);
        },
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.enter,
          padding: EdgeInsets.symmetric(horizontal: isActive ? 10 : 4, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: AppMotion.normal,
                curve: AppMotion.pop,
                scale: isActive ? 1.12 : 1,
                child: Icon(icon, size: 22, color: isActive ? color : AppColors.textDisabled),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppMotion.normal,
                style: (isActive ? AppTextStyles.navLabelActive : AppTextStyles.navLabel).copyWith(
                  color: isActive ? color : AppColors.textDisabled,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
