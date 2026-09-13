import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// What the student character is doing — one pose per menu.
enum StudentPose {
  /// Kompetensi / tujuan belajar — mengangkat bendera target.
  goal,

  /// Materi — membaca buku.
  reading,

  /// Simulasi — menjalankan simulasi jaringan di laptop.
  building,

  /// Test — mengerjakan soal dengan pensil.
  quiz,

  /// Progress — mengangkat piala.
  achievement,

  /// Refleksi — berpikir, muncul bohlam ide.
  reflecting,
}

/// Illustrated Indonesian senior-high (SMA) student mascot, painted in code in
/// a casual-game avatar style: chibi proportions, soft gradient shading, rim
/// light, a dark outline, and a contact shadow — the look of a mobile-game
/// character sheet rather than a flat icon set.
///
/// Drawn rather than shipped as artwork so it stays sharp at any size, costs
/// nothing to download, and can be recoloured per menu.
class StudentIcon extends StatelessWidget {
  const StudentIcon({
    super.key,
    required this.pose,
    this.size = 72,
    this.accent = AppColors.primaryBlue,
    this.hijab = false,
    this.showBackdrop = true,
  });

  final StudentPose pose;
  final double size;

  /// Colour of the prop and uniform trim; usually the menu's own colour.
  final Color accent;

  /// Two looks so the character set represents the whole class.
  final bool hijab;

  /// Soft glow disc behind the character, like a game avatar frame.
  final bool showBackdrop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StudentPainter(
          pose: pose,
          accent: accent,
          hijab: hijab,
          showBackdrop: showBackdrop,
        ),
      ),
    );
  }
}

class _StudentPainter extends CustomPainter {
  _StudentPainter({
    required this.pose,
    required this.accent,
    required this.hijab,
    required this.showBackdrop,
  });

  final StudentPose pose;
  final Color accent;
  final bool hijab;
  final bool showBackdrop;

  // Character palette — warm skin, ink outline, Indonesian school uniform.
  static const _skinLight = Color(0xFFFFD9B8);
  static const _skin = Color(0xFFF3BE95);
  static const _skinDark = Color(0xFFD79A72);
  static const _hairLight = Color(0xFF4A3B52);
  static const _hair = Color(0xFF2E2436);
  static const _ink = Color(0xFF2B2438);
  static const _shirt = Color(0xFFFFFFFF);
  static const _shirtShade = Color(0xFFDCE3F2);
  static const _uniform = Color(0xFFA6AEC2);
  static const _uniformDark = Color(0xFF7F889E);

  late double _u1;
  double u(double v) => v * _u1;

  Paint get _outline => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = u(2.4)
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;

  /// Fill with a top-to-bottom gradient so every shape reads as rounded.
  Paint _shaded(Rect rect, Color light, Color dark) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, dark],
    ).createShader(rect);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    _u1 = s / 100;
    final c = Offset(size.width / 2, size.height / 2);

    if (showBackdrop) _paintBackdrop(canvas, c);

    // The character (and anything it holds up) is drawn slightly smaller than
    // the box so raised props — flag, trophy, lightbulb — stay inside the
    // frame instead of being clipped at the top.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.82);
    canvas.translate(-c.dx, -c.dy + u(4));

    _paintGroundShadow(canvas, c);
    _paintBackProp(canvas, c);
    _paintBody(canvas, c);
    _paintHead(canvas, c);
    _paintFrontProp(canvas, c);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Offset c) {
    final rect = Rect.fromCenter(center: c, width: u(96), height: u(96));
    canvas.drawCircle(
      c,
      u(46),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.75)!,
            Color.lerp(accent, Colors.white, 0.45)!,
          ],
        ).createShader(rect),
    );
    // Highlight arc at the top of the disc, like a glossy game badge.
    canvas.drawArc(
      Rect.fromCenter(center: c, width: u(84), height: u(84)),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(3)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  void _paintGroundShadow(Canvas canvas, Offset c) {
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, u(40)), width: u(52), height: u(12)),
      Paint()
        ..color = _ink.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u(2.5)),
    );
  }

  // ─── Body ───

  void _paintBody(Canvas canvas, Offset c) {
    final hipY = c.dy + u(38);

    // Legs in grey uniform trousers
    for (final side in [-1.0, 1.0]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx + side * u(8), hipY - u(2)),
          width: u(12),
          height: u(20),
        ),
        Radius.circular(u(5)),
      );
      canvas.drawRRect(leg, _shaded(leg.outerRect, _uniform, _uniformDark));
      canvas.drawRRect(leg, _outline);
      // Shoe
      final shoe = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(c.dx + side * u(8), hipY + u(9)),
          width: u(14),
          height: u(7),
        ),
        topLeft: Radius.circular(u(3)),
        topRight: Radius.circular(u(3)),
        bottomLeft: Radius.circular(u(2)),
        bottomRight: Radius.circular(u(2)),
      );
      canvas.drawRRect(shoe, Paint()..color = _ink);
    }

    // Torso — white short-sleeve school shirt
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, u(18)), width: u(40), height: u(34)),
      Radius.circular(u(12)),
    );
    canvas.drawRRect(torso, _shaded(torso.outerRect, _shirt, _shirtShade));
    canvas.drawRRect(torso, _outline);

    // Collar
    final collar = Path()
      ..moveTo(c.dx - u(11), c.dy + u(4))
      ..lineTo(c.dx, c.dy + u(15))
      ..lineTo(c.dx + u(11), c.dy + u(4));
    canvas.drawPath(
      collar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(2.2)
        ..strokeJoin = StrokeJoin.round
        ..color = _ink,
    );

    // Badge on the chest, tinted with the menu colour
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(u(12), u(16)), width: u(9), height: u(6)),
      Radius.circular(u(2)),
    );
    canvas.drawRRect(badge, Paint()..color = accent);
    canvas.drawRRect(
      badge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(1.4)
        ..color = _ink,
    );

    // Belt line where shirt meets trousers
    final belt = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, u(31)), width: u(38), height: u(7)),
      Radius.circular(u(3)),
    );
    canvas.drawRRect(belt, _shaded(belt.outerRect, _uniform, _uniformDark));
    canvas.drawRRect(belt, _outline);

    _paintArms(canvas, c);
  }

  /// Arms are posed per prop: raised for the trophy and flag, forward for the
  /// book and laptop, one up for the idea.
  void _paintArms(Canvas canvas, Offset c) {
    void arm(double side, Offset hand, {double bend = 0}) {
      final shoulder = Offset(c.dx + side * u(18), c.dy + u(10));
      final control = Offset(shoulder.dx + side * u(12) + bend, (shoulder.dy + hand.dy) / 2);
      final path = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(control.dx, control.dy, hand.dx, hand.dy);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(9.5)
          ..strokeCap = StrokeCap.round
          ..color = _ink,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(6.5)
          ..strokeCap = StrokeCap.round
          ..color = _skin,
      );
      // Hand
      canvas.drawCircle(hand, u(5), Paint()..color = _skinLight);
      canvas.drawCircle(
        hand,
        u(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(2)
          ..color = _ink,
      );
    }

    switch (pose) {
      case StudentPose.reading:
      case StudentPose.building:
      case StudentPose.quiz:
        arm(-1, c.translate(-u(15), u(27)));
        arm(1, c.translate(u(15), u(27)));
      case StudentPose.achievement:
        arm(-1, c.translate(-u(19), u(6)), bend: -u(4));
        arm(1, c.translate(u(22), -u(10)), bend: u(10));
      case StudentPose.goal:
        arm(-1, c.translate(-u(19), u(22)));
        arm(1, c.translate(u(22), u(2)), bend: u(6));
      case StudentPose.reflecting:
        arm(-1, c.translate(-u(19), u(24)));
        arm(1, c.translate(u(13), u(0)), bend: u(8));
    }
  }

  // ─── Head ───

  void _paintHead(Canvas canvas, Offset c) {
    final head = c.translate(0, u(-18));
    final headRect = Rect.fromCenter(center: head, width: u(46), height: u(46));

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: head.translate(0, u(20)), width: u(12), height: u(10)),
        Radius.circular(u(4)),
      ),
      Paint()..color = _skinDark,
    );

    if (hijab) {
      final scarf = RRect.fromRectAndRadius(
        Rect.fromCenter(center: head.translate(0, u(4)), width: u(56), height: u(58)),
        Radius.circular(u(24)),
      );
      canvas.drawRRect(
        scarf,
        _shaded(
          scarf.outerRect,
          Color.lerp(accent, Colors.white, 0.62)!,
          Color.lerp(accent, Colors.white, 0.34)!,
        ),
      );
      canvas.drawRRect(scarf, _outline);
    } else {
      // Ears
      for (final side in [-1.0, 1.0]) {
        canvas.drawCircle(head.translate(side * u(22), u(3)), u(5), Paint()..color = _skin);
        canvas.drawCircle(
          head.translate(side * u(22), u(3)),
          u(5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = u(2)
            ..color = _ink,
        );
      }
    }

    // Face
    final face = RRect.fromRectAndRadius(headRect, Radius.circular(u(20)));
    canvas.drawRRect(face, _shaded(headRect, _skinLight, _skin));
    canvas.drawRRect(face, _outline);

    if (hijab) {
      // Scarf edge framing the face
      final frame = Path()
        ..moveTo(head.dx - u(24), head.dy + u(6))
        ..quadraticBezierTo(head.dx - u(26), head.dy - u(30), head.dx, head.dy - u(29))
        ..quadraticBezierTo(head.dx + u(26), head.dy - u(30), head.dx + u(24), head.dy + u(6))
        ..quadraticBezierTo(head.dx + u(16), head.dy - u(10), head.dx, head.dy - u(9))
        ..quadraticBezierTo(head.dx - u(16), head.dy - u(10), head.dx - u(24), head.dy + u(6))
        ..close();
      canvas.drawPath(
        frame,
        _shaded(
          frame.getBounds(),
          Color.lerp(accent, Colors.white, 0.52)!,
          Color.lerp(accent, Colors.white, 0.28)!,
        ),
      );
      canvas.drawPath(frame, _outline);
    } else {
      // Chunky game-style hair with a highlight streak
      final hair = Path()
        ..moveTo(head.dx - u(24), head.dy + u(2))
        ..quadraticBezierTo(head.dx - u(27), head.dy - u(32), head.dx + u(2), head.dy - u(28))
        ..quadraticBezierTo(head.dx + u(26), head.dy - u(26), head.dx + u(24), head.dy + u(2))
        ..quadraticBezierTo(head.dx + u(20), head.dy - u(12), head.dx + u(4), head.dy - u(11))
        ..quadraticBezierTo(head.dx - u(12), head.dy - u(9), head.dx - u(24), head.dy + u(2))
        ..close();
      canvas.drawPath(hair, _shaded(hair.getBounds(), _hairLight, _hair));
      canvas.drawPath(hair, _outline);
      canvas.drawArc(
        Rect.fromCenter(center: head.translate(-u(7), -u(19)), width: u(18), height: u(10)),
        math.pi * 1.05,
        math.pi * 0.55,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(2.6)
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    // Eyebrows
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(center: head.translate(side * u(9), -u(3)), width: u(11), height: u(8)),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(2.4)
          ..strokeCap = StrokeCap.round
          ..color = _hair,
      );
    }

    // Big glossy eyes
    for (final side in [-1.0, 1.0]) {
      final eye = head.translate(side * u(9), u(5));
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: u(10), height: u(12)),
        Paint()..color = _ink,
      );
      canvas.drawCircle(
        eye.translate(side * u(1.2), -u(2.4)),
        u(2.4),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        eye.translate(-side * u(1.6), u(2.8)),
        u(1.2),
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }

    // Blush
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: head.translate(side * u(16), u(11)), width: u(9), height: u(5)),
        Paint()..color = const Color(0xFFFF8FA3).withValues(alpha: 0.40),
      );
    }

    // Smile
    final smile = Path()
      ..moveTo(head.dx - u(5), head.dy + u(13))
      ..quadraticBezierTo(head.dx, head.dy + u(19), head.dx + u(5), head.dy + u(13));
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(2.4)
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
  }

  // ─── Props ───

  /// Props that sit behind the character (so hands overlap them).
  void _paintBackProp(Canvas canvas, Offset c) {
    switch (pose) {
      case StudentPose.goal:
        _paintFlag(canvas, c);
      case StudentPose.achievement:
        _paintTrophy(canvas, c);
      case StudentPose.reflecting:
        _paintIdea(canvas, c);
      default:
        break;
    }
  }

  /// Props held in front of the body.
  void _paintFrontProp(Canvas canvas, Offset c) {
    switch (pose) {
      case StudentPose.reading:
        _paintBook(canvas, c);
      case StudentPose.building:
        _paintLaptop(canvas, c);
      case StudentPose.quiz:
        _paintSheetAndPencil(canvas, c);
      default:
        break;
    }
  }

  void _paintBook(Canvas canvas, Offset c) {
    final base = c.translate(0, u(28));
    final left = Path()
      ..moveTo(base.dx - u(1), base.dy - u(9))
      ..lineTo(base.dx - u(19), base.dy - u(5))
      ..lineTo(base.dx - u(19), base.dy + u(7))
      ..lineTo(base.dx - u(1), base.dy + u(3))
      ..close();
    final right = Path()
      ..moveTo(base.dx + u(1), base.dy - u(9))
      ..lineTo(base.dx + u(19), base.dy - u(5))
      ..lineTo(base.dx + u(19), base.dy + u(7))
      ..lineTo(base.dx + u(1), base.dy + u(3))
      ..close();
    for (final page in [left, right]) {
      canvas.drawPath(page, _shaded(page.getBounds(), Colors.white, const Color(0xFFE6ECF8)));
      canvas.drawPath(page, _outline);
    }
    // Spine + a couple of text lines
    canvas.drawLine(
      base.translate(0, -u(9)),
      base.translate(0, u(3)),
      Paint()
        ..strokeWidth = u(2.4)
        ..color = accent,
    );
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 2; i++) {
        canvas.drawLine(
          base.translate(side * u(5), -u(4) + u(4.0 * i)),
          base.translate(side * u(15), -u(6) + u(4.0 * i)),
          Paint()
            ..strokeWidth = u(1.3)
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: 0.5),
        );
      }
    }
  }

  void _paintLaptop(Canvas canvas, Offset c) {
    final base = c.translate(0, u(29));
    final screen = RRect.fromRectAndRadius(
      Rect.fromCenter(center: base.translate(0, -u(6)), width: u(34), height: u(22)),
      Radius.circular(u(3)),
    );
    canvas.drawRRect(
      screen,
      _shaded(screen.outerRect, Color.lerp(accent, Colors.white, 0.2)!, accent),
    );
    canvas.drawRRect(screen, _outline);

    final inner = RRect.fromRectAndRadius(
      Rect.fromCenter(center: base.translate(0, -u(6)), width: u(27), height: u(15)),
      Radius.circular(u(2)),
    );
    canvas.drawRRect(inner, Paint()..color = Colors.white.withValues(alpha: 0.95));

    // Miniature network topology on the screen
    final nodes = [
      base.translate(-u(7), -u(9)),
      base.translate(u(7), -u(9)),
      base.translate(0, -u(2)),
    ];
    for (var i = 0; i < 2; i++) {
      canvas.drawLine(
        nodes[i],
        nodes[2],
        Paint()
          ..strokeWidth = u(1.4)
          ..color = accent,
      );
    }
    for (final n in nodes) {
      canvas.drawCircle(n, u(2.4), Paint()..color = accent);
    }

    final deck = RRect.fromRectAndRadius(
      Rect.fromCenter(center: base.translate(0, u(7)), width: u(42), height: u(6)),
      Radius.circular(u(2.5)),
    );
    canvas.drawRRect(deck, _shaded(deck.outerRect, _uniform, _uniformDark));
    canvas.drawRRect(deck, _outline);
  }

  void _paintSheetAndPencil(Canvas canvas, Offset c) {
    final sheet = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(-u(3), u(28)), width: u(30), height: u(24)),
      Radius.circular(u(3)),
    );
    canvas.drawRRect(sheet, _shaded(sheet.outerRect, Colors.white, const Color(0xFFE6ECF8)));
    canvas.drawRRect(sheet, _outline);
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        c.translate(-u(13), u(22) + u(5.0 * i)),
        c.translate(u(5), u(22) + u(5.0 * i)),
        Paint()
          ..strokeWidth = u(1.6)
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.45),
      );
    }
    // Pencil held in the right hand
    canvas.save();
    canvas.translate(c.dx + u(17), c.dy + u(24));
    canvas.rotate(-math.pi / 4.5);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: u(6), height: u(26)),
      Radius.circular(u(1.6)),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.gold);
    canvas.drawRRect(body, _outline);
    final tip = Path()
      ..moveTo(-u(3), u(13))
      ..lineTo(u(3), u(13))
      ..lineTo(0, u(19))
      ..close();
    canvas.drawPath(tip, Paint()..color = _skinLight);
    canvas.drawPath(tip, _outline);
    canvas.restore();
  }

  void _paintFlag(Canvas canvas, Offset c) {
    final pole = c.translate(u(26), u(0));
    canvas.drawLine(
      pole.translate(0, -u(30)),
      pole.translate(0, u(28)),
      Paint()
        ..strokeWidth = u(3.6)
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
    final flag = Path()
      ..moveTo(pole.dx + u(1), pole.dy - u(30))
      ..lineTo(pole.dx + u(23), pole.dy - u(22))
      ..lineTo(pole.dx + u(1), pole.dy - u(13))
      ..close();
    canvas.drawPath(
      flag,
      _shaded(flag.getBounds(), Color.lerp(accent, Colors.white, 0.25)!, accent),
    );
    canvas.drawPath(flag, _outline);
  }

  void _paintTrophy(Canvas canvas, Offset c) {
    final cup = c.translate(u(30), -u(34));
    final body = Path()
      ..moveTo(cup.dx - u(12), cup.dy - u(8))
      ..lineTo(cup.dx + u(12), cup.dy - u(8))
      ..quadraticBezierTo(cup.dx + u(11), cup.dy + u(10), cup.dx, cup.dy + u(11))
      ..quadraticBezierTo(cup.dx - u(11), cup.dy + u(10), cup.dx - u(12), cup.dy - u(8))
      ..close();
    canvas.drawPath(body, _shaded(body.getBounds(), AppColors.goldLight, AppColors.goldDark));
    canvas.drawPath(body, _outline);

    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(center: cup.translate(side * u(14), -u(2)), width: u(12), height: u(14)),
        side < 0 ? math.pi / 2 : -math.pi / 2,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(3)
          ..color = AppColors.goldDark,
      );
    }

    canvas.drawLine(
      cup.translate(0, u(11)),
      cup.translate(0, u(15)),
      Paint()
        ..strokeWidth = u(4)
        ..color = AppColors.goldDark,
    );
    final foot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: cup.translate(0, u(18)), width: u(18), height: u(5)),
      Radius.circular(u(2)),
    );
    canvas.drawRRect(foot, Paint()..color = AppColors.goldDark);
    canvas.drawRRect(foot, _outline);

    // Sparkles
    for (final o in [Offset(-u(24), -u(10)), Offset(u(23), -u(4)), Offset(-u(18), u(8))]) {
      _paintSparkle(canvas, cup + o, u(3.4));
    }
  }

  void _paintSparkle(Canvas canvas, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.goldLight);
  }

  void _paintIdea(Canvas canvas, Offset c) {
    final bulb = c.translate(u(28), -u(34));
    canvas.drawCircle(bulb, u(14), Paint()..color = AppColors.goldLight);
    canvas.drawCircle(
      bulb,
      u(14),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(2.4)
        ..color = _ink,
    );
    final cap = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bulb.translate(0, u(16)), width: u(12), height: u(8)),
      Radius.circular(u(2)),
    );
    canvas.drawRRect(cap, Paint()..color = AppColors.goldDark);
    canvas.drawRRect(cap, _outline);

    final filament = Path()
      ..moveTo(bulb.dx - u(4), bulb.dy + u(4))
      ..lineTo(bulb.dx - u(1.5), bulb.dy - u(3))
      ..lineTo(bulb.dx + u(1.5), bulb.dy + u(3))
      ..lineTo(bulb.dx + u(4), bulb.dy - u(4));
    canvas.drawPath(
      filament,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u(2)
        ..strokeCap = StrokeCap.round
        ..color = AppColors.goldDark,
    );

    for (var i = 0; i < 5; i++) {
      final angle = -math.pi * 0.95 + i * math.pi * 0.24;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        bulb + dir * u(18),
        bulb + dir * u(23),
        Paint()
          ..strokeWidth = u(2.4)
          ..strokeCap = StrokeCap.round
          ..color = AppColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudentPainter old) =>
      old.pose != pose ||
      old.accent != accent ||
      old.hijab != hijab ||
      old.showBackdrop != showBackdrop;
}
