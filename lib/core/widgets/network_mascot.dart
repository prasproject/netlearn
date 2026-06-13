import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// NetLearn mascot — custom painted robot character with bounce animation.
/// Replaces Lottie with a custom painting that works without external assets.
class NetworkMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const NetworkMascot({
    super.key,
    this.size = 90,
    this.animate = true,
  });

  @override
  State<NetworkMascot> createState() => _NetworkMascotState();
}

class _NetworkMascotState extends State<NetworkMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.primaryBlueLight,
          borderRadius: BorderRadius.circular(widget.size * 0.22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: CustomPaint(
          painter: _MascotPainter(),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body
    final bodyPaint = Paint()..color = AppColors.primaryBlueAccent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.64, h * 0.52),
        Radius.circular(w * 0.15),
      ),
      bodyPaint,
    );

    // Eyes (screens)
    final eyeBg = Paint()..color = AppColors.primaryBlue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.33, w * 0.22, h * 0.16),
        Radius.circular(w * 0.06),
      ),
      eyeBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.54, h * 0.33, w * 0.22, h * 0.16),
        Radius.circular(w * 0.06),
      ),
      eyeBg,
    );

    // Pupils
    final pupilPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(w * 0.35, h * 0.41),
      w * 0.05,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.65, h * 0.41),
      w * 0.05,
      pupilPaint,
    );

    // Mouth
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.56, w * 0.28, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      eyeBg,
    );

    // Antenna
    final antennaPaint = Paint()..color = AppColors.accentOrangeWarm;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.10, w * 0.10, h * 0.19),
        Radius.circular(w * 0.04),
      ),
      antennaPaint,
    );
    final antennaBall = Paint()..color = AppColors.accentOrangeLight;
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.10),
      w * 0.06,
      antennaBall,
    );

    // Arms
    final armPaint = Paint()..color = AppColors.primaryBlueSky;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.40, w * 0.14, h * 0.24),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.80, h * 0.40, w * 0.14, h * 0.24),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.74, w * 0.16, h * 0.12),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, h * 0.74, w * 0.16, h * 0.12),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
