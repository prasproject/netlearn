/// NetLearn — N-Gain Calculator
/// Calculates normalized gain between pre-test and post-test scores.
class NGainCalculator {
  NGainCalculator._();

  /// Calculate N-Gain: (postScore - preScore) / (maxScore - preScore)
  /// Returns value between 0.0 and 1.0
  static double calculate({
    required int preScore,
    required int postScore,
    int maxScore = 100,
  }) {
    if (maxScore <= preScore) return 0.0;
    final gain = (postScore - preScore) / (maxScore - preScore);
    return gain.clamp(0.0, 1.0);
  }

  /// Get category label based on N-Gain value
  static String getCategory(double nGain) {
    if (nGain >= 0.7) return 'Tinggi';
    if (nGain >= 0.3) return 'Sedang';
    return 'Rendah';
  }

  /// Get descriptive text
  static String getDescription(double nGain) {
    if (nGain >= 0.7) return 'Tinggi — Sangat Baik!';
    if (nGain >= 0.3) return 'Sedang — Baik!';
    return 'Rendah — Perlu Peningkatan';
  }
}

/// NetLearn — XP Service
class XPService {
  XPService._();

  static const int materialCompleteXP = 5;
  static const int checkpointCompleteXP = 10;
  static const int quizCompleteXP = 20;
  static const int pretestXP = 15;
  static const int perfectScoreBonus = 10;
  static const int streakBonusXP = 5;

  /// Calculate XP earned from a quiz based on score
  static int calculateQuizXP(int score, int baseXP) {
    int xp = baseXP;
    if (score >= 90) xp += perfectScoreBonus;
    if (score >= 70) xp += 5;
    return xp;
  }

  /// Calculate level from total XP
  static int calculateLevel(int totalXP) {
    // Each level requires level * 100 XP
    int level = 1;
    int xpNeeded = 100;
    int remaining = totalXP;
    while (remaining >= xpNeeded) {
      remaining -= xpNeeded;
      level++;
      xpNeeded = level * 100;
    }
    return level;
  }
}
