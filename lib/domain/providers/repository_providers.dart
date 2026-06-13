import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/simulation_repository.dart';

import '../../data/repositories/firebase/rtdb_auth_repository.dart';
import '../../data/repositories/firebase/rtdb_material_repository.dart';
import '../../data/repositories/firebase/rtdb_quiz_repository.dart';
import '../../data/repositories/firebase/rtdb_progress_repository.dart';
import '../../data/repositories/firebase/rtdb_simulation_repository.dart';

/// ─── Repository Providers ───
/// Central registry for all data repositories.
/// Currently configured to use Firebase Realtime Database.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RtdbAuthRepository();
});

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return RtdbMaterialRepository();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return RtdbQuizRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return RtdbProgressRepository();
});

final simulationRepositoryProvider = Provider<SimulationRepository>((ref) {
  return RtdbSimulationRepository();
});
