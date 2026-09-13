@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/constants/app_colors.dart';
import 'package:netlearn/core/widgets/student_icon.dart';

/// Renders the menu cards with the student character set to PNG for visual
/// review. See iso_render_preview_test.dart for how to run it.
void main() {
  testWidgets('preview kartu menu dengan karakter siswa', (tester) async {
    final out = Platform.environment['ISO_PREVIEW_DIR'] ??
        Directory.systemTemp.createTempSync('netlearn_ui').path;

    final iconsPath = Platform.environment['MATERIAL_FONT'];
    if (iconsPath != null && File(iconsPath).existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(File(iconsPath).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }

    const menus = [
      ('Kompetensi', AppColors.progressTeal, StudentPose.goal, false),
      ('Materi', AppColors.primaryBlue, StudentPose.reading, true),
      ('Simulasi', AppColors.secondaryGreen, StudentPose.building, false),
      ('Test', AppColors.accentOrange, StudentPose.quiz, true),
      ('Progress', AppColors.purple, StudentPose.achievement, false),
      ('Refleksi', AppColors.quizPink, StudentPose.reflecting, true),
    ];

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // Brand gradient band, to judge the blue over a large area.
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.brandGradient,
                      stops: AppColors.brandGradientStops,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(10),
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: [
                      for (final (title, color, pose, hijab) in menus)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(color, Colors.white, 0.12)!,
                                Color.lerp(color, Colors.black, 0.10)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StudentIcon(
                                pose: pose,
                                size: 96,
                                accent: color,
                                hijab: hijab,
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/menu_characters.png').writeAsBytesSync(
        data!.buffer.asUint8List(),
      );
    });
  });
}
