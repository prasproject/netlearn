import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/audio_provider.dart';

/// Register Screen — WhatsApp number + OTP.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    
    if (name.isEmpty || username.isEmpty || phoneNumber.isEmpty || password.isEmpty) return;
    
    final success = await ref
        .read(authProvider.notifier)
        .register(name, username, phoneNumber, password);
    if (success && mounted) {
      context.go('/home');
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
            colors: [AppColors.secondaryGreen, Color(0xFF0D3B10)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.school_rounded, size: 60, color: Colors.white70),
                const SizedBox(height: 12),
                Text(AppStrings.register, style: AppTextStyles.splashTitle)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text(AppStrings.registerSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 36),
                
                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: _buildRegisterForm(authState),
                ).animate().slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                
                const SizedBox(height: 20),
                Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppStrings.hasAccount, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(AppStrings.login, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryGreenAccent)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AuthState authState) {
    return Column(
      key: const ValueKey('register_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Buat Akun', style: AppTextStyles.screenTitle.copyWith(color: AppColors.secondaryGreen)),
        const SizedBox(height: 8),
        Text(
          'Masukkan nama, username, nomor WhatsApp, dan password Anda.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController, 
          decoration: const InputDecoration(hintText: 'Nama Lengkap', labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline, size: 20)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            hintText: 'Username',
            labelText: 'Username',
            prefixIcon: Icon(Icons.person, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            hintText: '08xxxxxxxxxx',
            labelText: 'Nomor WhatsApp',
            prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 14),
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
          text: authState.isLoading ? 'Memproses...' : 'Daftar',
          backgroundColor: AppColors.secondaryGreen,
          shadowColor: AppColors.secondaryGreenDark,
          onPressed: authState.isLoading ? null : _register,
          width: double.infinity,
        ),
      ],
    );
  }
}
