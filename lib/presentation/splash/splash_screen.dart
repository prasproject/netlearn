import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/network_mascot.dart';
import '../../domain/providers/auth_provider.dart';

/// Splash Screen — Animated mascot, loading bar, auto-navigate.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animateProgress();
  }

  Future<void> _animateProgress() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() => _progress = i / 10);
    }
    if (!mounted) return;

    await ref.read(authProvider.notifier).initializeSession();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isLoggedIn) {
      final isAdmin = authState.user?.role == 'admin';
      context.go(isAdmin ? '/admin' : '/home');
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Color(0xFF0A3575)],
          ),
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(top: -60, right: -80, child: _circle(260, 0.05)),
            Positioned(bottom: -40, left: -50, child: _circle(180, 0.05)),
            Positioned(top: 100, left: 20, child: _circle(100, 0.05)),
            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NetworkMascot(size: 100),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.splashTitle,
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.appTagline,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 140,
                    child: AnimatedProgressBar(
                      progress: _progress,
                      height: 5,
                      gradientColors: const [
                        AppColors.primaryBlueAccent,
                        AppColors.primaryBlueSky,
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
            // Version text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                AppStrings.appVersion,
                textAlign: TextAlign.center,
                style: AppTextStyles.versionText,
              ).animate().fadeIn(delay: 800.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
