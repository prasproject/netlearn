import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Animated, custom-painted illustrations for the welcome tour.
///
/// Drawn in code rather than shipped as images so every scene stays crisp on
/// any screen, keeps the web build small, and can actually animate — the old
/// tutorial only showed a blurred spotlight with one line of text.

/// Shared chrome: a soft blob backdrop with slowly drifting network dots.
class _SceneFrame extends StatelessWidget {
  const _SceneFrame({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.02)],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

mixin _Looping<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ─── 1. Welcome: mascot orbited by network nodes ───

class WelcomeScene extends StatefulWidget {
  const WelcomeScene({super.key});

  @override
  State<WelcomeScene> createState() => _WelcomeSceneState();
}

class _WelcomeSceneState extends State<WelcomeScene> with SingleTickerProviderStateMixin, _Looping {
  @override
  Widget build(BuildContext context) {
    return _SceneFrame(
      color: AppColors.primaryBlue,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            CustomPaint(size: const Size(230, 230), painter: _WelcomePainter(controller.value)),
      ),
    );
  }
}

class _WelcomePainter extends CustomPainter {
  _WelcomePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 82.0;
    final angleBase = t * 2 * math.pi;

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.primaryBlue.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, orbit);

    // Satellites travelling around the mascot, linked back to the centre.
    const count = 5;
    final icons = [
      AppColors.primaryBlueLight,
      AppColors.secondaryGreenLight,
      AppColors.accentOrange,
      AppColors.purpleLight,
      AppColors.progressTealLight,
    ];
    for (var i = 0; i < count; i++) {
      final angle = angleBase + (i * 2 * math.pi / count);
      final p = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(
        center,
        p,
        Paint()
          ..strokeWidth = 1
          ..color = icons[i].withValues(alpha: 0.35),
      );
      final pulse = 1 + 0.25 * math.sin(angleBase * 2 + i);
      canvas.drawCircle(p, 9 * pulse, Paint()..color = icons[i].withValues(alpha: 0.18));
      canvas.drawCircle(p, 6, Paint()..color = icons[i]);
    }

    // Mascot body
    final bob = math.sin(angleBase) * 3;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, bob), width: 78, height: 66),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 4)),
      Paint()..color = AppColors.primaryBlueDark.withValues(alpha: 0.25),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.primaryBlue);

    // Eyes that blink on the loop
    final blink = math.sin(angleBase * 1.5).abs() > 0.96;
    final eyePaint = Paint()..color = Colors.white;
    for (final dx in [-15.0, 15.0]) {
      final eye = center.translate(dx, bob - 4);
      if (blink) {
        canvas.drawLine(
          eye.translate(-6, 0),
          eye.translate(6, 0),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 3,
        );
      } else {
        canvas.drawCircle(eye, 7, eyePaint);
        canvas.drawCircle(eye, 3.2, Paint()..color = AppColors.primaryBlueDark);
      }
    }

    // Smile
    final smile = Path()
      ..moveTo(center.dx - 12, center.dy + bob + 14)
      ..quadraticBezierTo(center.dx, center.dy + bob + 22, center.dx + 12, center.dy + bob + 14);
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = Colors.white,
    );

    // Antenna
    canvas.drawLine(
      center.translate(0, bob - 33),
      center.translate(0, bob - 46),
      Paint()
        ..strokeWidth = 3
        ..color = AppColors.primaryBlue,
    );
    canvas.drawCircle(
      center.translate(0, bob - 50),
      6 + math.sin(angleBase * 3) * 1.5,
      Paint()..color = AppColors.accentOrangeGold,
    );
  }

  @override
  bool shouldRepaint(covariant _WelcomePainter old) => old.t != t;
}

// ─── 2. Learning journey: pre-test → material → practice → post-test ───

class JourneyScene extends StatefulWidget {
  const JourneyScene({super.key});

  @override
  State<JourneyScene> createState() => _JourneySceneState();
}

class _JourneySceneState extends State<JourneyScene> with SingleTickerProviderStateMixin, _Looping {
  static const _steps = [
    ('Pre-Test', Icons.quiz_rounded, AppColors.accentOrange),
    ('Materi', Icons.menu_book_rounded, AppColors.primaryBlue),
    ('Latihan', Icons.edit_note_rounded, AppColors.purple),
    ('Post-Test', Icons.emoji_events_rounded, AppColors.secondaryGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return _SceneFrame(
      color: AppColors.accentOrange,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          // One step lights up at a time, then the whole path stays lit.
          final active = (controller.value * _steps.length).floor();
          return SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  _row(i, i <= active),
                  if (i < _steps.length - 1) _connector(i < active),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(int index, bool lit) {
    final (label, icon, color) = _steps[index];
    return AnimatedScale(
      duration: const Duration(milliseconds: 320),
      scale: lit ? 1 : 0.92,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: lit ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: lit ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lit ? color.withValues(alpha: 0.45) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: lit ? color : AppColors.textDisabled),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: lit ? color : AppColors.textDisabled,
                ),
              ),
              if (lit) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, size: 15, color: color.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _connector(bool lit) {
    return Container(
      width: 2,
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: lit ? AppColors.accentOrange.withValues(alpha: 0.5) : AppColors.divider,
    );
  }
}

// ─── 3. Material slides ───

class MaterialScene extends StatefulWidget {
  const MaterialScene({super.key});

  @override
  State<MaterialScene> createState() => _MaterialSceneState();
}

class _MaterialSceneState extends State<MaterialScene>
    with SingleTickerProviderStateMixin, _Looping {
  @override
  Widget build(BuildContext context) {
    return _SceneFrame(
      color: AppColors.primaryBlueLight,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          return SizedBox(
            width: 240,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 2; i >= 0; i--) _card(i, t),
                Positioned(bottom: 6, child: _progressBar(t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(int depth, double t) {
    // Front card slides away and the stack steps forward, like reading slides.
    final shift = depth == 0 ? Curves.easeInOut.transform(math.min(1, t * 1.6)) : 0.0;
    return Transform.translate(
      offset: Offset(shift * 90, -depth * 10.0),
      child: Transform.rotate(
        angle: shift * 0.12,
        child: Opacity(
          opacity: depth == 0 ? 1 - shift * 0.65 : 1,
          child: Container(
            width: 168 - depth * 12,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.lan_rounded, color: AppColors.primaryBlueLight, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                for (final w in [1.0, 0.75, 0.5])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: FractionallySizedBox(
                      widthFactor: w,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressBar(double t) {
    return Container(
      width: 150,
      height: 8,
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(99)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.25 + t * 0.7,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryGreenLight,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 4. Simulation: packet hopping across devices ───

class SimulationScene extends StatefulWidget {
  const SimulationScene({super.key});

  @override
  State<SimulationScene> createState() => _SimulationSceneState();
}

class _SimulationSceneState extends State<SimulationScene>
    with SingleTickerProviderStateMixin, _Looping {
  @override
  Widget build(BuildContext context) {
    return _SceneFrame(
      color: AppColors.secondaryGreen,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            CustomPaint(size: const Size(250, 200), painter: _SimulationPainter(controller.value)),
      ),
    );
  }
}

class _SimulationPainter extends CustomPainter {
  _SimulationPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = <Offset>[
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.40, size.height * 0.30),
      Offset(size.width * 0.68, size.height * 0.70),
      Offset(size.width * 0.90, size.height * 0.28),
    ];
    final icons = [
      Icons.computer_rounded,
      Icons.router_rounded,
      Icons.device_hub_rounded,
      Icons.dns_rounded,
    ];
    final colors = [
      AppColors.primaryBlueLight,
      AppColors.secondaryGreenLight,
      AppColors.purpleLight,
      AppColors.accentOrange,
    ];

    // Cables
    final cable = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.secondaryGreenAccent;
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], cable);
    }

    // Packet travelling the whole route
    final seg = (t * (nodes.length - 1));
    final idx = seg.floor().clamp(0, nodes.length - 2);
    final local = seg - idx;
    final packet = Offset.lerp(nodes[idx], nodes[idx + 1], local)!;
    canvas.drawCircle(
      packet,
      14,
      Paint()..color = AppColors.accentOrangeGold.withValues(alpha: 0.25),
    );
    canvas.drawCircle(packet, 7, Paint()..color = AppColors.accentOrange);

    // Devices
    for (var i = 0; i < nodes.length; i++) {
      final reached = seg >= i - 0.15;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: nodes[i], width: 44, height: 44),
        const Radius.circular(13),
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = reached ? 2.4 : 1.4
          ..color = reached ? colors[i] : AppColors.divider,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icons[i].codePoint),
          style: TextStyle(
            fontSize: 22,
            fontFamily: icons[i].fontFamily,
            package: icons[i].fontPackage,
            color: reached ? colors[i] : AppColors.textDisabled,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, nodes[i] - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SimulationPainter old) => old.t != t;
}

// ─── 5. Rewards: XP bar, level, streak, badge ───

class RewardScene extends StatefulWidget {
  const RewardScene({super.key});

  @override
  State<RewardScene> createState() => _RewardSceneState();
}

class _RewardSceneState extends State<RewardScene> with SingleTickerProviderStateMixin, _Looping {
  @override
  Widget build(BuildContext context) {
    return _SceneFrame(
      color: AppColors.gold,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = Curves.easeOut.transform(math.min(1, controller.value * 1.4));
          final pop = math.sin(controller.value * math.pi).clamp(0.0, 1.0);
          return SizedBox(
            width: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.9 + pop * 0.18,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.45 * pop),
                          blurRadius: 26,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('⭐ ${(t * 120).round()} XP', AppColors.secondaryGreenLight),
                    const SizedBox(width: 8),
                    _chip('Lv ${1 + (t * 2).round()}', AppColors.purpleLight),
                    const SizedBox(width: 8),
                    _chip('🔥 ${(t * 5).round()} Hari', AppColors.accentOrange),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.1 + t * 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.accentOrange],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
