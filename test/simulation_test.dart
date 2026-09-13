import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/data/models/simulation_model.dart';
import 'package:netlearn/data/repositories/simulation_repository.dart';
import 'package:netlearn/data/seed/seed_data.dart';
import 'package:netlearn/domain/providers/simulation_provider.dart';
import 'package:netlearn/presentation/simulation/iso_canvas.dart';
import 'package:netlearn/presentation/simulation/simulation_missions.dart';
import 'dart:ui';

class FakeSimulationRepository implements SimulationRepository {
  @override
  Future<List<SimulationModel>> getAllSimulations() async => SeedData.simulations;

  @override
  Future<SimulationModel> getSimulation(String id) async =>
      SeedData.simulations.firstWhere((s) => s.id == id);
}

Future<SimulationNotifier> _playgroundNotifier() async {
  final notifier = SimulationNotifier(FakeSimulationRepository());
  await Future<void>.delayed(Duration.zero);
  notifier.setSimulation('sim-playground');
  return notifier;
}

void main() {
  group('Lab Bebas', () {
    test('tersedia sebagai simulasi yang bisa dipilih', () {
      expect(
        SeedData.simulations.any((s) => s.id == 'sim-playground'),
        isTrue,
        reason: 'mode bangun-sendiri harus ada di daftar simulasi',
      );
    });

    test('perangkat bisa ditambah, disambung, lalu paket terkirim', () async {
      final notifier = await _playgroundNotifier();
      final startNodes = notifier.state.simulation.nodes.length;

      notifier.addNode(NodeType.pc);
      expect(notifier.state.simulation.nodes.length, startNodes + 1);

      // PC → Switch memakai kabel straight (perangkat berbeda jenis).
      notifier.setCableType(CableType.straight);
      notifier.handleNodeTap('pc-1');
      notifier.handleNodeTap('sw-1');
      expect(notifier.state.simulation.connections.length, 1);

      notifier.setCableType(CableType.straight);
      notifier.handleNodeTap('sw-1');
      notifier.handleNodeTap('srv-1');
      expect(notifier.state.simulation.connections.length, 2);

      notifier.setPacketEndpoints(sourceId: 'pc-1', targetId: 'srv-1');
      final ok = await notifier.sendPacket();

      expect(ok, isTrue);
      expect(notifier.state.statusMessage, contains('✓'));
      expect(notifier.state.selectedPath, ['pc-1', 'sw-1', 'srv-1']);
      notifier.dispose();
    });

    test('beda subnet tanpa router ditolak dengan penjelasan', () async {
      final notifier = await _playgroundNotifier();
      notifier.setCableType(CableType.straight);
      notifier.handleNodeTap('pc-1');
      notifier.handleNodeTap('sw-1');
      notifier.handleNodeTap('sw-1');
      notifier.handleNodeTap('srv-1');

      // Pindahkan server ke jaringan lain tanpa menambah router.
      notifier.updateNodeIp('srv-1', '10.20.30.40');
      notifier.setPacketEndpoints(sourceId: 'pc-1', targetId: 'srv-1');

      final ok = await notifier.sendPacket();
      expect(ok, isFalse);
      expect(notifier.state.statusMessage, contains('subnet'));
      notifier.dispose();
    });
  });

  group('Proyeksi isometrik', () {
    test('menggeser layar diterjemahkan kembali ke koordinat lantai', () {
      const camera = IsoCamera(zoom: 1.4, rotation: 0.6);
      final projection = IsoProjection(size: const Size(400, 600), camera: camera);

      const before = Offset(0.3, 0.4);
      final delta = projection.unprojectDelta(const Offset(40, 20));
      final after = before + delta;

      // Memindahkan node sejauh delta hasil unproject harus menggeser titik
      // proyeksinya persis sejauh gerakan layar tadi.
      final moved =
          projection.project(after.dx, after.dy) - projection.project(before.dx, before.dy);
      expect(moved.dx, closeTo(40, 0.001));
      expect(moved.dy, closeTo(20, 0.001));
    });
  });

  group('Misi terpandu', () {
    test('Lab Bebas memakai daftar langkah bangun-jaringan', () {
      final missions = SimulationMissions.forSimulation('sim-playground');
      expect(missions.length, greaterThanOrEqualTo(5));
      expect(
        missions.first.isDone(
          SimulationState(simulation: SeedData.simulations.first),
          const MissionStats(),
        ),
        isFalse,
      );
      expect(
        missions.first.isDone(
          SimulationState(simulation: SeedData.simulations.first),
          const MissionStats(cameraMoved: true),
        ),
        isTrue,
      );
    });

    test('topologi tetap memakai daftar langkah amati-kirim', () {
      final missions = SimulationMissions.forSimulation('sim-star');
      expect(missions.length, 4);
    });
  });
}
