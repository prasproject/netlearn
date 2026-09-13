import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/data/models/progress_model.dart';
import 'package:netlearn/domain/providers/auth_provider.dart';
import 'package:netlearn/domain/providers/progress_provider.dart';

import 'fakes.dart';

void main() {
  group('ProgressModel', () {
    test('copyWith dapat mengosongkan skor dan tanggal selesai', () {
      const p = ProgressModel(
        unitId: 'unit-1',
        materialsCompleted: 3,
        totalMaterials: 3,
        pretestScore: 80,
        finalScore: 90,
        practiceScore: 70,
      );

      final cleared = p.copyWith(
        pretestScore: null,
        finalScore: null,
        practiceScore: null,
        completedAt: null,
      );

      expect(cleared.pretestScore, isNull);
      expect(cleared.finalScore, isNull);
      expect(cleared.practiceScore, isNull);
      expect(cleared.completedAt, isNull);
    });

    test('copyWith tanpa argumen mempertahankan nilai lama', () {
      const p = ProgressModel(
        unitId: 'unit-1',
        materialsCompleted: 1,
        totalMaterials: 3,
        pretestScore: 80,
      );
      expect(p.copyWith(materialsCompleted: 2).pretestScore, 80);
    });

    test('toUpdateJson tidak mengirim skor yang tidak dimiliki model', () {
      const p = ProgressModel(unitId: 'unit-1', materialsCompleted: 1, totalMaterials: 3);
      final json = p.toUpdateJson();

      // Absent keys leave the stored score untouched on a partial update.
      expect(json.containsKey('pretestScore'), isFalse);
      expect(json.containsKey('finalScore'), isFalse);
      expect(json.containsKey('checkpointScores'), isFalse);
      expect(json['materialsCompleted'], 1);
    });
  });

  group('ProgressNotifier', () {
    test('mengikuti perubahan dari stream database', () async {
      final repo = FakeProgressRepository();
      final notifier = ProgressNotifier(repo, 'siswa1');
      await Future<void>.delayed(Duration.zero);

      repo.emit(const [
        ProgressModel(unitId: 'unit-1', materialsCompleted: 2, totalMaterials: 3),
        ProgressModel(unitId: '__overall__', materialsCompleted: 0, totalMaterials: 0, pretestScore: 55),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.unitProgressFor('unit-1')?.materialsCompleted, 2);
      expect(notifier.state.overallPretestScore, 55);

      // A reset on the server must clear the score locally too.
      repo.emit(const [
        ProgressModel(unitId: 'unit-1', materialsCompleted: 0, totalMaterials: 3),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.overallPretestScore, isNull);
      notifier.dispose();
      await repo.close();
    });

    test('tulis gagal tidak dihitung selesai dan memunculkan syncError', () async {
      final repo = FakeProgressRepository(realtime: false)..failWrites = true;
      final notifier = ProgressNotifier(repo, 'siswa1');
      await Future<void>.delayed(Duration.zero);

      final completed = await notifier.completeMaterial('unit-1', totalSlides: 1);

      expect(completed, isFalse, reason: 'progress yang gagal disimpan tidak boleh dianggap selesai');
      expect(notifier.state.syncError, isNotNull);
      notifier.dispose();
      await repo.close();
    });
  });

  group('AuthNotifier', () {
    test('toggle audio tersimpan ke repository', () async {
      final repo = FakeAuthRepository(testStudent());
      final notifier = AuthNotifier(repo);
      await notifier.initializeSession();

      await notifier.toggleAudio();

      expect(notifier.state.user!.settings.audioEnabled, isFalse);
      expect(repo.user!.settings.audioEnabled, isFalse,
          reason: 'perubahan setting harus ikut tersimpan, bukan hanya di memori');
      notifier.dispose();
    });

    test('XP memakai penulisan atomik dan memakai nilai dari database', () async {
      final repo = FakeAuthRepository(testStudent());
      final notifier = AuthNotifier(repo);
      await notifier.initializeSession();

      await notifier.addXP(20);

      expect(notifier.state.user!.xp, 60);
      expect(repo.user!.xp, 60);
      notifier.dispose();
    });

    test('XP gagal disimpan dikembalikan ke nilai semula', () async {
      final repo = FakeAuthRepository(testStudent())..failWrites = true;
      final notifier = AuthNotifier(repo);
      await notifier.initializeSession();

      await notifier.addXP(20);

      expect(notifier.state.user!.xp, 40, reason: 'XP yang gagal disimpan tidak boleh tampil di UI');
      expect(notifier.state.syncError, isNotNull);
      notifier.dispose();
    });
  });
}
