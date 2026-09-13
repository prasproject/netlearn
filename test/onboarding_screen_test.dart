import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netlearn/domain/providers/repository_providers.dart';
import 'package:netlearn/presentation/onboarding/onboarding_screen.dart';

import 'fakes.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // GetStorage needs a documents directory; point it at the temp dir.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('netlearn_test').path,
    );
    // Tests must not hit the network for fonts. The resulting "font not
    // bundled" notices are noise, so they are filtered out rather than failing
    // tests about screen behaviour.
    GoogleFonts.config.allowRuntimeFetching = false;
    await GetStorage.init();
  });

  /// google_fonts reports a load failure for every style while offline; those
  /// are noise here, not a defect in the screen under test.
  void drainFontErrors(WidgetTester tester) {
    while (tester.takeException() != null) {}
  }

  testWidgets('panduan awal bisa dilalui langkah demi langkah', (tester) async {
    // The binding installs its own handler per test, so filter here.
    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('allowRuntimeFetching')) return;
      defaultOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = defaultOnError);

    await tester.pumpWidget(
      ProviderScope(
        // Stubbed so the screen doesn't reach for Firebase in a unit test.
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(testStudent())),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    drainFontErrors(tester);

    expect(find.text('SELAMAT DATANG'), findsOneWidget);
    expect(find.text('Langkah 1 dari 5'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    for (var step = 2; step <= 5; step++) {
      await tester.tap(find.text('Lanjut'));
      // The page slide runs on a repeating-animation screen, so step the clock
      // manually instead of pumpAndSettle (which would never settle).
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      drainFontErrors(tester);
      expect(find.text('Langkah $step dari 5'), findsOneWidget);
    }

    // Final page offers the closing action instead of another "Lanjut".
    expect(find.text('Mulai Belajar'), findsOneWidget);
    expect(find.text('Lanjut'), findsNothing);
    drainFontErrors(tester);
  });
}
