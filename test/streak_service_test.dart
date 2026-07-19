import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/domain/services/streak_service.dart';

void main() {
  group('StreakService.refresh', () {
    test('hari pertama dengan streak 0 menjadi 1', () {
      final now = DateTime(2026, 6, 13, 10);
      final result = StreakService.refresh(
        currentStreak: 0,
        lastActive: DateTime(2026, 6, 13, 8),
        now: now,
      );

      expect(result.streak, 1);
      expect(result.increased, isTrue);
    });

    test('buka aplikasi di hari yang sama tidak menaikkan streak', () {
      final result = StreakService.refresh(
        currentStreak: 5,
        lastActive: DateTime(2026, 6, 13, 8),
        now: DateTime(2026, 6, 13, 20),
      );

      expect(result.streak, 5);
      expect(result.increased, isFalse);
    });

    test('aktivitas berturut-turut menaikkan streak', () {
      final result = StreakService.refresh(
        currentStreak: 3,
        lastActive: DateTime(2026, 6, 12, 9),
        now: DateTime(2026, 6, 13, 9),
      );

      expect(result.streak, 4);
      expect(result.increased, isTrue);
    });

    test('lewat lebih dari 1 hari mereset streak ke 1', () {
      final result = StreakService.refresh(
        currentStreak: 10,
        lastActive: DateTime(2026, 6, 1, 9),
        now: DateTime(2026, 6, 13, 9),
      );

      expect(result.streak, 1);
      expect(result.increased, isFalse);
    });
  });
}
