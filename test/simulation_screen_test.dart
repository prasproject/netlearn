import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netlearn/data/models/simulation_model.dart';
import 'package:netlearn/data/repositories/simulation_repository.dart';
import 'package:netlearn/data/seed/seed_data.dart';
import 'package:netlearn/domain/providers/repository_providers.dart';
import 'package:netlearn/presentation/simulation/iso_canvas.dart';
import 'package:netlearn/presentation/simulation/simulation_screen.dart';

import 'fakes.dart';

class FakeSimulationRepository implements SimulationRepository {
  @override
  Future<List<SimulationModel>> getAllSimulations() async => SeedData.simulations;

  @override
  Future<SimulationModel> getSimulation(String id) async =>
      SeedData.simulations.firstWhere((s) => s.id == id);
}

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('netlearn_sim').path,
    );
    GoogleFonts.config.allowRuntimeFetching = false;
    await GetStorage.init();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('allowRuntimeFetching')) return;
      defaultOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = defaultOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          simulationRepositoryProvider.overrideWithValue(FakeSimulationRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(testStudent())),
          progressRepositoryProvider.overrideWithValue(FakeProgressRepository(realtime: false)),
        ],
        child: const MaterialApp(home: SimulationScreen()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The isometric canvas, picked out from the several `CustomPaint` widgets
  /// Flutter's own framework/Material widgets also use internally — matching
  /// `find.byType(CustomPaint).first` grabs whichever of those happens to
  /// come first in the tree, not necessarily our own painter.
  Finder findIsoCanvas() =>
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter is IsoScenePainter);

  testWidgets('langkah misi maju setelah kamera digerakkan', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    expect(
      find.textContaining('Langkah 1 dari '),
      findsOneWidget,
      reason: 'mulai dari langkah pertama',
    );

    // Memutar kanvas lewat tombol kamera harus menyelesaikan langkah pertama.
    await tester.tap(find.byIcon(Icons.rotate_right_rounded));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.textContaining('Langkah 1 dari '),
      findsNothing,
      reason: 'langkah pertama sudah selesai, kartu harus pindah ke langkah berikutnya',
    );
  });

  testWidgets('menggeser perangkat juga menyelesaikan langkah pertama', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    expect(find.textContaining('Langkah 1 dari '), findsOneWidget);

    // Di browser desktop, menyeret di kanvas biasanya mengenai perangkat,
    // bukan area kosong — itu tetap harus dihitung sebagai menjelajah tampilan.
    await tester.drag(findIsoCanvas(), const Offset(40, 25));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Langkah 1 dari '), findsNothing);
  });

  testWidgets('zoom dengan roda mouse menyelesaikan langkah pertama', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    expect(find.textContaining('Langkah 1 dari '), findsOneWidget);

    final center = tester.getCenter(findIsoCanvas());
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Langkah 1 dari '), findsNothing);
  });

  testWidgets(
    'status bar tidak pernah berada di atas tombol kamera dalam urutan tumpukan',
    (tester) async {
      // Regresi untuk bug "tombol kamera mati": status bar TIDAK interaktif,
      // jadi ia tidak boleh datang setelah (di atas) tombol kamera dalam
      // urutan children Stack — kalau tidak, ia memenangkan pengujian-tekan
      // secara geometris tanpa benar-benar menangani sentuhan itu, dan
      // sentuhan pada tombol di baliknya lenyap begitu saja.
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpScreen(tester);

      final stack = tester.widget<Stack>(
        find.ancestor(
          of: find.byKey(const Key('simStatusBar')),
          matching: find.byType(Stack),
        ),
      );
      final statusIndex = stack.children.indexWhere(
        (w) => w is Positioned && w.child.key == const Key('simStatusBar'),
      );
      final cameraIndex = stack.children.indexWhere(
        (w) => w is Positioned && w.child is Column,
      );

      expect(statusIndex, isNonNegative);
      expect(cameraIndex, isNonNegative);
      expect(
        statusIndex,
        lessThan(cameraIndex),
        reason: 'status bar harus ditambahkan sebelum tombol kamera agar tidak menutupinya',
      );
    },
  );
}
