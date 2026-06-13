import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_welcome_kit/flutter_welcome_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/tutorial_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
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
        _startTutorialIfNeeded();
      },
    );

    _tutorialTriggerSub = ref.listenManual<int>(tutorialTriggerProvider, (
      prev,
      next,
    ) {
      if (prev == next) return;
      _startTutorialIfNeeded(force: true);
    });
  }

  @override
  void dispose() {
    _tourController?.end();
    _tutorialTriggerSub?.close();
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

      final hasSeenTutorial =
          _storage.read('main_menu_tutorial_seen_$userId') == true;
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
          title: 'Menu Beranda',
          description: 'Ini halaman ringkasan aktivitas belajarmu.',
          icon: Icons.home_rounded,
          backgroundColor: AppColors.primaryBlue,
        ),
        TourStep(
          key: _materialKey,
          title: 'Menu Materi',
          description: 'Akses semua unit materi pembelajaran di sini.',
          icon: Icons.menu_book_rounded,
          backgroundColor: AppColors.secondaryGreen,
        ),
        TourStep(
          key: _simulationKey,
          title: 'Menu Simulasi',
          description: 'Coba simulasi jaringan secara interaktif.',
          icon: Icons.hub_rounded,
          backgroundColor: AppColors.accentOrange,
        ),
        TourStep(
          key: _progressKey,
          title: 'Menu Progress',
          description: 'Pantau nilai, badge, dan perkembanganmu.',
          icon: Icons.bar_chart_rounded,
          backgroundColor: AppColors.purple,
        ),
        TourStep(
          key: _profileKey,
          title: 'Menu Profil',
          description: 'Kelola profil dan pengaturan akunmu.',
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Beranda', navKey: _homeKey),
                _navItem(
                  1,
                  Icons.menu_book_rounded,
                  'Materi',
                  navKey: _materialKey,
                ),
                _navItem(
                  2,
                  Icons.hub_rounded,
                  'Simulasi',
                  navKey: _simulationKey,
                ),
                _navItem(
                  3,
                  Icons.bar_chart_rounded,
                  'Progress',
                  navKey: _progressKey,
                ),
                _navItem(
                  4,
                  Icons.person_rounded,
                  'Profil',
                  navKey: _profileKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    String label, {
    required GlobalKey navKey,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      key: navKey,
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primaryBlue : AppColors.textDisabled,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.navLabelActive
                  : AppTextStyles.navLabel,
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
