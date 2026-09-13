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

  testWidgets('langkah misi maju setelah kamera digerakkan', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    expect(find.textContaining('Langkah 1/'), findsOneWidget, reason: 'mulai dari langkah pertama');

    // Memutar kanvas lewat tombol kamera harus menyelesaikan langkah pertama.
    await tester.tap(find.byIcon(Icons.rotate_right_rounded));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.textContaining('Langkah 1/'),
      findsNothing,
      reason: 'langkah pertama sudah selesai, kartu harus pindah ke langkah berikutnya',
    );
  });

  testWidgets('menggeser perangkat juga menyelesaikan langkah pertama', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    expect(find.textContaining('Langkah 1/'), findsOneWidget);

    // Di browser desktop, menyeret di kanvas biasanya mengenai perangkat,
    // bukan area kosong — itu tetap harus dihitung sebagai menjelajah tampilan.
    final canvas = find.byType(CustomPaint).first;
    await tester.drag(canvas, const Offset(40, 25));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Langkah 1/'), findsNothing);
  });

  testWidgets('zoom dengan roda mouse menyelesaikan langkah pertama', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    expect(find.textContaining('Langkah 1/'), findsOneWidget);

    final center = tester.getCenter(find.byType(CustomPaint).first);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Langkah 1/'), findsNothing);
  });
}
