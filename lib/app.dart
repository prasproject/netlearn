import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/progress_provider.dart';

/// NetLearn App — Root widget with theme and router configuration.
class NetLearnApp extends ConsumerWidget {
  const NetLearnApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch theme provider for dark mode toggle
    return MaterialApp.router(
      title: 'NetLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: messengerKey,
      routerConfig: AppRouter.router,
      builder: (context, child) => _SyncErrorListener(child: child ?? const SizedBox()),
    );
  }
}

/// Shows a single, app-wide notice whenever a write to Firebase fails, so the
/// user is never left believing something was saved when it wasn't.
class _SyncErrorListener extends ConsumerWidget {
  const _SyncErrorListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      progressProvider.select((s) => s.syncError),
      (previous, next) => _show(ref, next, onShown: () {
        ref.read(progressProvider.notifier).clearSyncError();
      }),
    );

    ref.listen<String?>(
      authProvider.select((s) => s.syncError),
      (previous, next) => _show(ref, next, onShown: () {
        ref.read(authProvider.notifier).clearSyncError();
      }),
    );

    return child;
  }

  void _show(WidgetRef ref, String? message, {required VoidCallback onShown}) {
    if (message == null) return;
    final messenger = NetLearnApp.messengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
    onShown();
  }
}
