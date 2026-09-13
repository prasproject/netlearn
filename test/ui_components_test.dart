import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/widgets/animated_progress_bar.dart';
import 'package:netlearn/core/widgets/pressable.dart';
import 'package:netlearn/core/widgets/surface_card.dart';

void main() {
  testWidgets('Pressable memanggil aksi saat aktif', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pressable(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Pressable));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('Pressable yang dinonaktifkan tidak bisa ditekan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pressable(
            enabled: false,
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Pressable));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 0);
  });

  testWidgets('SurfaceCard dengan onTap ikut menerima efek tekan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurfaceCard(
            onTap: () => taps++,
            child: const Text('isi kartu'),
          ),
        ),
      ),
    );

    expect(find.byType(Pressable), findsOneWidget);
    await tester.tap(find.text('isi kartu'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('AnimatedProgressBar mengisi dari kiri, bukan dari tengah',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              // Same shape as the home header: a Column that centres its
              // children, which is what exposed the old layout bug.
              child: Column(
                children: [
                  AnimatedProgressBar(progress: 0.4, height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    final track = tester.getRect(find.byType(AnimatedProgressBar));
    final fill = tester.getRect(find.byType(FractionallySizedBox));

    expect(track.width, 300, reason: 'track harus selebar ruang yang tersedia');
    expect(fill.left, track.left, reason: 'isian harus menempel ke tepi kiri');
    expect(fill.width, closeTo(120, 0.5), reason: '40% dari 300');
  });
}
