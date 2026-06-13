import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/network_mascot.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/audio_provider.dart';

/// Login Screen — WhatsApp number + OTP.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isEmpty || password.isEmpty) return;
    
    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.role == 'admin') {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Color(0xFF0A3575)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const NetworkMascot(size: 80),
                const SizedBox(height: 12),
                Text(AppStrings.appName, style: AppTextStyles.splashTitle)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text(AppStrings.loginSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 36),
                
                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: _buildLoginForm(authState),
                ).animate().slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                
                Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppStrings.noAccount, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(AppStrings.register,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlueAccent),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthState authState) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Masuk', style: AppTextStyles.screenTitle.copyWith(color: AppColors.primaryBlue)),
        const SizedBox(height: 8),
        Text('Masukkan Username dan Password Anda.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 20),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            hintText: 'Username',
            labelText: 'Username',
            prefixIcon: Icon(Icons.person, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock, size: 20),
          ),
        ),
        if (authState.authError != null) ...[
          const SizedBox(height: 12),
          Text(authState.authError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: 24),
        GradientButton(
          text: authState.isLoading ? 'Memproses...' : 'Masuk',
          onPressed: authState.isLoading ? null : _login,
          width: double.infinity,
        ),
      ],
    );
  }
}
