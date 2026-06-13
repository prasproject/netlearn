import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tombol kembali di header — ke menu utama (`/home`) atau pop jika ada di stack.
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key});

  static void navigateToHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToHome(context),
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
    );
  }
}
