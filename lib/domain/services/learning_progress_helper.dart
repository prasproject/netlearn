import '../../data/models/material_model.dart';
import '../../data/models/progress_model.dart';

/// Target unit + slide untuk fitur "Lanjut Belajar".
class ContinueLearningTarget {
  final String unitId;
  final int slideIndex;
  final String title;
  final int completedSlides;
  final int totalSlides;

  const ContinueLearningTarget({
    required this.unitId,
    required this.slideIndex,
    required this.title,
    required this.completedSlides,
    required this.totalSlides,
  });

  String get subtitle {
    if (completedSlides <= 0) return 'Mulai belajar';
    if (completedSlides >= totalSlides) return '$totalSlides/$totalSlides Materi Selesai';
    return '$completedSlides/$totalSlides Materi Selesai';
  }
}

/// Helper progres belajar yang selalu memakai jumlah slide materi terbaru.
class LearningProgressHelper {
  LearningProgressHelper._();

  static List<MaterialModel> sortedUnits(List<MaterialModel> materials) {
    return List<MaterialModel>.from(materials)
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        if (o != 0) return o;
        return a.unitNumber.compareTo(b.unitNumber);
      });
  }

  static ProgressModel? progressFor(
    String unitId,
    List<ProgressModel> progress,
  ) {
    try {
      return progress.firstWhere((p) => p.unitId == unitId);
    } catch (_) {
      return null;
    }
  }

  static int completedSlides(ProgressModel? stored, MaterialModel unit) {
    return (stored?.materialsCompleted ?? 0).clamp(0, unit.totalSlides);
  }

  static bool isUnitCompleted(ProgressModel? stored, MaterialModel unit) {
    return completedSlides(stored, unit) >= unit.totalSlides;
  }

  static bool isUnitUnlocked({
    required int unitIndex,
    required List<MaterialModel> orderedUnits,
    required List<ProgressModel> progress,
  }) {
    if (unitIndex <= 0) return true;
    final prev = orderedUnits[unitIndex - 1];
    return isUnitCompleted(progressFor(prev.id, progress), prev);
  }

  /// Slide berikutnya yang belum dibaca (0-based).
  static int resumeSlideIndex(ProgressModel? stored, MaterialModel unit) {
    final done = completedSlides(stored, unit);
    if (done >= unit.totalSlides) return 0;
    return done.clamp(0, unit.totalSlides - 1);
  }

  /// Tentukan unit & slide untuk "Lanjut Belajar" berdasarkan materi terbaru.
  static ContinueLearningTarget? resolveContinueTarget({
    required List<MaterialModel> materials,
    required List<ProgressModel> progress,
  }) {
    final units = sortedUnits(materials);
    if (units.isEmpty) return null;

    for (var i = 0; i < units.length; i++) {
      if (!isUnitUnlocked(
        unitIndex: i,
        orderedUnits: units,
        progress: progress,
      )) {
        break;
      }

      final unit = units[i];
      final stored = progressFor(unit.id, progress);
      final done = completedSlides(stored, unit);
      if (done < unit.totalSlides) {
        return ContinueLearningTarget(
          unitId: unit.id,
          slideIndex: resumeSlideIndex(stored, unit),
          title: 'Unit ${unit.unitNumber} — ${unit.title}',
          completedSlides: done,
          totalSlides: unit.totalSlides,
        );
      }
    }

    // Semua unit terbuka sudah selesai — tampilkan unit terakhir yang terbuka.
    for (var i = units.length - 1; i >= 0; i--) {
      if (!isUnitUnlocked(
        unitIndex: i,
        orderedUnits: units,
        progress: progress,
      )) {
        continue;
      }
      final unit = units[i];
      final stored = progressFor(unit.id, progress);
      final done = completedSlides(stored, unit);
      return ContinueLearningTarget(
        unitId: unit.id,
        slideIndex: 0,
        title: 'Unit ${unit.unitNumber} — ${unit.title}',
        completedSlides: done,
        totalSlides: unit.totalSlides,
      );
    }

    final first = units.first;
    return ContinueLearningTarget(
      unitId: first.id,
      slideIndex: 0,
      title: 'Unit ${first.unitNumber} — ${first.title}',
      completedSlides: 0,
      totalSlides: first.totalSlides,
    );
  }
}
