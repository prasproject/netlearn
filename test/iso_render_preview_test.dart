@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/data/seed/seed_data.dart';
import 'package:netlearn/domain/providers/simulation_provider.dart';
import 'package:netlearn/presentation/simulation/iso_canvas.dart';

/// Renders the isometric scene to PNG files so the drawing can be checked
/// without launching the app.
///
/// Run with:
///   ISO_PREVIEW_DIR=/tmp/netlearn flutter test --tags preview \
///     test/iso_render_preview_test.dart
/// Images land in ISO_PREVIEW_DIR (default: the system temp directory).
void main() {
  /// Loads a real font so the preview shows true text widths instead of the
  /// block-glyph placeholder the test environment uses by default.
  Future<void> loadFont(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }

  testWidgets('render preview kanvas isometrik', (tester) async {
    final out = Platform.environment['ISO_PREVIEW_DIR'] ??
        Directory.systemTemp.createTempSync('netlearn_iso').path;
    final icons = Platform.environment['MATERIAL_FONT'];
    await loadFont('Nunito', 'google_fonts/Nunito-Bold.ttf');
    await loadFont('Roboto', 'google_fonts/Nunito-Bold.ttf');
    if (icons != null) await loadFont('MaterialIcons', icons);

    Future<void> shot(String name, IsoScenePainter painter, Size size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFF0F4FF),
      );
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name').writeAsBytesSync(data!.buffer.asUint8List());
    }

    await tester.runAsync(() async {
      const size = Size(420, 520);

      final star = SeedData.simulations.firstWhere((s) => s.id == 'sim-star');
      await shot(
        'iso_star.png',
        IsoScenePainter(
          simulation: star,
          camera: const IsoCamera(zoom: 1.05),
          cableByLinkKey: const {},
          activePath: const ['pc-left', 'switch-star', 'server-star'],
          packetProgress: 1.45,
          time: 0.3,
          sourceNodeId: 'pc-left',
          targetNodeId: 'server-star',
          selectedNodeId: 'switch-star',
        ),
        size,
      );

      final lab = SeedData.simulations.firstWhere((s) => s.id == 'sim-playground');
      await shot(
        'iso_lab_rotated.png',
        IsoScenePainter(
          simulation: lab,
          camera: const IsoCamera(zoom: 1.15, rotation: 0.6),
          cableByLinkKey: const {'pc-1|sw-1': CableType.straight},
          activePath: const [],
          packetProgress: -1,
          time: 0.7,
        ),
        size,
      );
    });
  });
}
