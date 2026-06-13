import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/navigation/main_navigation.dart';
import '../../presentation/material/material_list_screen.dart';
import '../../presentation/material/material_detail_screen.dart';
import '../../presentation/material/material_learning_video_screen.dart';
import '../../presentation/simulation/simulation_screen.dart';
import '../../presentation/quiz/pretest_screen.dart';
import '../../presentation/quiz/posttest_quiz_screen.dart';
import '../../presentation/quiz/test_menu_screen.dart';
import '../../presentation/quiz/checkpoint_screen.dart';
import '../../presentation/quiz/quiz_screen.dart';
import '../../presentation/quiz/feedback_screen.dart';
import '../../presentation/progress/progress_screen.dart';
import '../../presentation/progress/post_test_screen.dart';
import '../../presentation/certificate/certificate_screen.dart';
import '../../presentation/profile/profile_screen.dart';

// Admin Screens
import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/admin/manage_materials_screen.dart';
import '../../presentation/admin/student_monitor_screen.dart';
import '../../presentation/admin/combined_reporting_screen.dart';

/// NetLearn — App Router Configuration
/// Uses GoRouter with named routes and slide transitions.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Splash ──
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(
          state,
          const SplashScreen(),
        ),
      ),

      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _buildPage(
          state,
          const RegisterScreen(),
        ),
      ),

      // ── Main Navigation Shell ──
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPage(
          state,
          const MainNavigation(),
        ),
      ),

      // ── Admin Routes ──
      GoRoute(
        path: '/admin',
        name: 'admin',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/materials',
        name: 'manageMaterials',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const ManageMaterialsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/students',
        name: 'studentMonitor',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const StudentMonitorScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/reporting',
        name: 'combinedReporting',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const CombinedReportingScreen(),
        ),
      ),

      // ── Material ──
      GoRoute(
        path: '/materials',
        name: 'materials',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const MaterialListScreen(),
        ),
      ),
      GoRoute(
        path: '/material/learning-video',
        name: 'materialLearningVideo',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const MaterialLearningVideoScreen(),
        ),
      ),
      GoRoute(
        path: '/material/:unitId',
        name: 'materialDetail',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId'] ?? '1';
          return _buildSlide(
            state,
            MaterialDetailScreen(unitId: unitId),
          );
        },
      ),

      // ── Simulation ──
      GoRoute(
        path: '/simulation',
        name: 'simulation',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const SimulationScreen(),
        ),
      ),

      // ── Quiz Routes ──
      GoRoute(
        path: '/test',
        name: 'testMenu',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const TestMenuScreen(),
        ),
      ),
      GoRoute(
        path: '/pretest',
        name: 'pretest',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const PretestScreen(),
        ),
      ),
      GoRoute(
        path: '/posttest',
        name: 'posttest',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const PosttestQuizScreen(),
        ),
      ),
      GoRoute(
        path: '/checkpoint/:unitId',
        name: 'checkpoint',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId'] ?? '1';
          return _buildSlide(
            state,
            CheckpointScreen(unitId: unitId),
          );
        },
      ),
      GoRoute(
        path: '/quiz/:unitId',
        name: 'quiz',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId'] ?? '1';
          return _buildSlide(
            state,
            QuizScreen(unitId: unitId),
          );
        },
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildSlide(
            state,
            FeedbackScreen(
              score: extra['score'] as int? ?? 0,
              totalQuestions: extra['totalQuestions'] as int? ?? 10,
              xpEarned: extra['xpEarned'] as int? ?? 0,
              quizType: extra['quizType'] as String? ?? 'quiz',
              unitTitle: extra['unitTitle'] as String? ?? '',
            ),
          );
        },
      ),

      // ── Progress ──
      GoRoute(
        path: '/progress',
        name: 'progress',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const ProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/post-test',
        name: 'postTest',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const PostTestScreen(),
        ),
      ),

      // ── Certificate ──
      GoRoute(
        path: '/certificate',
        name: 'certificate',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const CertificateScreen(),
        ),
      ),

      // ── Profile ──
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildSlide(
          state,
          const ProfileScreen(),
        ),
      ),
    ],
  );

  /// Standard fade transition for main pages
  static CustomTransitionPage _buildPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide transition for sub-pages
  static CustomTransitionPage _buildSlide(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
