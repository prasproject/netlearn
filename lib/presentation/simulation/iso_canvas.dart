import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/simulation_model.dart';
import '../../domain/providers/simulation_provider.dart';

/// Camera over the isometric ground plane: where it looks, how close, and how
/// far it has been spun around the vertical axis.
class IsoCamera {
  const IsoCamera({this.pan = Offset.zero, this.zoom = 1, this.rotation = 0});

  final Offset pan;
  final double zoom;
  final double rotation;

  IsoCamera copyWith({Offset? pan, double? zoom, double? rotation}) => IsoCamera(
    pan: pan ?? this.pan,
    zoom: (zoom ?? this.zoom).clamp(0.55, 2.2),
    rotation: rotation ?? this.rotation,
  );
}

/// Projects the simulation's normalised (0..1) grid coordinates onto the
/// screen with a 2:1 isometric transform.
///
/// Devices are still positioned in plain grid space — the existing topology
/// data and routing logic are untouched — this class is only the "camera" that
/// makes that flat grid read as a three-dimensional room.
class IsoProjection {
  IsoProjection({required this.size, required this.camera}) {
    // Tile size chosen so a full 0..1 grid fits the canvas at zoom 1.
    tileWidth = size.width * 0.38 * camera.zoom;
    tileHeight = tileWidth * 0.52;
    origin = Offset(size.width / 2, size.height * 0.42) + camera.pan;
  }

  final Size size;
  final IsoCamera camera;

  late final double tileWidth;
  late final double tileHeight;
  late final Offset origin;

  /// Grid point (0..1, 0..1) → screen point.
  Offset project(double nx, double ny) {
    final gx = nx - 0.5;
    final gy = ny - 0.5;
    final c = math.cos(camera.rotation);
    final s = math.sin(camera.rotation);
    final rx = gx * c - gy * s;
    final ry = gx * s + gy * c;
    return origin + Offset((rx - ry) * tileWidth, (rx + ry) * tileHeight);
  }

  /// Screen drag delta → grid delta, so dragging a device follows the finger
  /// along the tilted floor rather than the screen axes.
  Offset unprojectDelta(Offset screenDelta) {
    final a = screenDelta.dx / tileWidth;
    final b = screenDelta.dy / tileHeight;
    final drx = (a + b) / 2;
    final dry = (b - a) / 2;
    final c = math.cos(-camera.rotation);
    final s = math.sin(-camera.rotation);
    return Offset(drx * c - dry * s, drx * s + dry * c);
  }

  /// Depth key for painter's-algorithm sorting (far objects drawn first).
  double depthOf(double nx, double ny) {
    final gx = nx - 0.5;
    final gy = ny - 0.5;
    final c = math.cos(camera.rotation);
    final s = math.sin(camera.rotation);
    return (gx * c - gy * s) + (gx * s + gy * c);
  }
}

/// Visual spec of one device type: box size, colours, and icon.
class _DeviceStyle {
  const _DeviceStyle(this.top, this.side, this.accent, this.icon, this.height);
  final Color top;
  final Color side;
  final Color accent;
  final IconData icon;
  final double height;
}

_DeviceStyle _styleFor(NodeType type) => switch (type) {
  NodeType.pc => const _DeviceStyle(
    Color(0xFF8FA7F0),
    Color(0xFF4A63C8),
    AppColors.primaryBlue,
    Icons.computer_rounded,
    26,
  ),
  NodeType.router => const _DeviceStyle(
    Color(0xFF7FD3A6),
    Color(0xFF2F8F5B),
    AppColors.secondaryGreen,
    Icons.router_rounded,
    20,
  ),
  NodeType.switchDevice => const _DeviceStyle(
    Color(0xFFC0AEEE),
    Color(0xFF6F53BE),
    AppColors.purple,
    Icons.device_hub_rounded,
    16,
  ),
  NodeType.server => const _DeviceStyle(
    Color(0xFFF5B583),
    Color(0xFFC1662F),
    AppColors.accentOrange,
    Icons.dns_rounded,
    38,
  ),
};

Color cableColor(CableType type) => switch (type) {
  CableType.straight => AppColors.secondaryGreenLight,
  CableType.cross => AppColors.accentOrangeLight,
  CableType.wifi => AppColors.primaryBlueSky,
};

/// The isometric scene: floor, cables, devices, and the packet in flight.
class IsoScenePainter extends CustomPainter {
  IsoScenePainter({
    required this.simulation,
    required this.camera,
    required this.cableByLinkKey,
    required this.activePath,
    required this.packetProgress,
    required this.time,
    this.selectedNodeId,
    this.connectStartNodeId,
    this.sourceNodeId,
    this.targetNodeId,
    this.showGrid = true,
  });

  final SimulationModel simulation;
  final IsoCamera camera;
  final Map<String, CableType> cableByLinkKey;
  final List<String> activePath;

  /// Position of the packet along [activePath], in hops (e.g. 1.5 = halfway
  /// between the second and third device). Negative means "no packet".
  final double packetProgress;

  /// Free-running clock (0..1) used for idle animation: blinking lights,
  /// pulsing rings, and the flow of data along active links.
  final double time;

  final String? selectedNodeId;
  final String? connectStartNodeId;
  final String? sourceNodeId;
  final String? targetNodeId;
  final bool showGrid;

  static String linkKeyOf(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = IsoProjection(size: size, camera: camera);

    _paintFloor(canvas, size, p);
    _paintCables(canvas, p);
    _paintDevices(canvas, p);
    _paintPacket(canvas, p);
  }

  // ─── Floor ───

  void _paintFloor(Canvas canvas, Size size, IsoProjection p) {
    // Ground slab
    final corners = [
      p.project(-0.05, -0.05),
      p.project(1.05, -0.05),
      p.project(1.05, 1.05),
      p.project(-0.05, 1.05),
    ];
    final slab = Path()..addPolygon(corners, true);
    canvas.drawPath(
      slab,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondaryGreenSurface, const Color(0xFFD7ECDA)],
        ).createShader(slab.getBounds()),
    );
    canvas.drawPath(
      slab,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.secondaryGreenAccent,
    );

    if (!showGrid) return;

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.secondaryGreenAccent.withValues(alpha: 0.55);
    const steps = 8;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      canvas.drawLine(p.project(t, 0), p.project(t, 1), grid);
      canvas.drawLine(p.project(0, t), p.project(1, t), grid);
    }
  }

  // ─── Cables ───

  void _paintCables(Canvas canvas, IsoProjection p) {
    for (final conn in simulation.connections) {
      final from = _nodeById(conn.fromNodeId);
      final to = _nodeById(conn.toNodeId);
      if (from == null || to == null) continue;

      final a = p.project(from.x, from.y);
      final b = p.project(to.x, to.y);
      final type = cableByLinkKey[linkKeyOf(from.id, to.id)] ?? CableType.straight;
      final onPath = _isOnActivePath(from.id, to.id);

      // Cables sag between devices; wireless links arc upward instead.
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final bow = type == CableType.wifi ? -26.0 : 14.0;
      final control = mid.translate(0, bow);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);

      // Drop shadow of the cable on the floor keeps it grounded.
      canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.black.withValues(alpha: 0.06),
      );

      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = onPath ? 5 : 3
        ..color = onPath ? cableColor(type) : cableColor(type).withValues(alpha: 0.45);

      if (type == CableType.wifi) {
        _drawDashed(canvas, path, base, dash: 9, gap: 7);
      } else {
        canvas.drawPath(path, base);
        // Highlight line along the top of the cable for a rounded look.
        canvas.drawPath(
          path.shift(const Offset(0, -1.2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = onPath ? 1.6 : 1
            ..color = Colors.white.withValues(alpha: onPath ? 0.5 : 0.25),
        );
      }

      if (onPath) _paintFlowDots(canvas, path);
    }
  }

  /// Little dots streaming along an active link, so a live route reads as
  /// carrying traffic even before a packet is sent.
  void _paintFlowDots(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    for (var i = 0; i < 3; i++) {
      final t = ((time + i / 3) % 1);
      final pos = metric.getTangentForOffset(metric.length * t)?.position;
      if (pos == null) continue;
      canvas.drawCircle(pos, 2.4, Paint()..color = Colors.white.withValues(alpha: 0.75));
    }
  }

  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  // ─── Devices ───

  void _paintDevices(Canvas canvas, IsoProjection p) {
    // Painter's algorithm: devices further back are drawn first so nearer ones
    // overlap them correctly.
    final ordered = [...simulation.nodes]
      ..sort((a, b) => p.depthOf(a.x, a.y).compareTo(p.depthOf(b.x, b.y)));

    for (final node in ordered) {
      // Plate first, then the box: a device standing in front always covers
      // the name tag behind it, never the other way round, so no label can
      // hide a device.
      final showIp =
          node.id == selectedNodeId || node.id == sourceNodeId || node.id == targetNodeId;
      _paintPlate(canvas, node, p.project(node.x, node.y), camera.zoom, showIp: showIp);
      _paintDevice(canvas, p, node);
    }
  }

  void _paintDevice(Canvas canvas, IsoProjection p, NetworkNode node) {
    final style = _styleFor(node.type);
    final base = p.project(node.x, node.y);
    final zoom = camera.zoom;
    final w = 34.0 * zoom;
    final h = 18.0 * zoom;
    final boxHeight = style.height * zoom;

    final isSelected = node.id == selectedNodeId;
    final isConnectStart = node.id == connectStartNodeId;
    final isEndpoint = node.id == sourceNodeId || node.id == targetNodeId;

    // Contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: base.translate(4 * zoom, 3 * zoom), width: w * 1.5, height: h * 1.15),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Selection / connection ring pulsing on the floor
    if (isSelected || isConnectStart || isEndpoint) {
      final ringColor = isConnectStart
          ? AppColors.accentOrange
          : isSelected
          ? AppColors.primaryBlue
          : AppColors.gold;
      final pulse = 1 + 0.12 * math.sin(time * 2 * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: base, width: w * 1.9 * pulse, height: h * 1.5 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ringColor.withValues(alpha: 0.85),
      );
    }

    // Box corners (diamond footprint extruded upward)
    final top = base.translate(0, -boxHeight);
    final left = Offset(-w / 2, 0);
    final right = Offset(w / 2, 0);
    final front = Offset(0, h / 2);
    final back = Offset(0, -h / 2);

    Offset at(Offset o, {double lift = 0}) => base.translate(o.dx, o.dy - lift);

    final topFace = Path()
      ..addPolygon([
        at(back, lift: boxHeight),
        at(right, lift: boxHeight),
        at(front, lift: boxHeight),
        at(left, lift: boxHeight),
      ], true);
    final leftFace = Path()
      ..addPolygon([
        at(left, lift: boxHeight),
        at(front, lift: boxHeight),
        at(front),
        at(left),
      ], true);
    final rightFace = Path()
      ..addPolygon([
        at(right, lift: boxHeight),
        at(front, lift: boxHeight),
        at(front),
        at(right),
      ], true);

    canvas.drawPath(leftFace, Paint()..color = style.side);
    canvas.drawPath(rightFace, Paint()..color = Color.lerp(style.side, Colors.black, 0.18)!);
    canvas.drawPath(topFace, Paint()..color = style.top);
    canvas.drawPath(
      topFace,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.6),
    );

    // Status LED blinking on the front face
    final ledOn = ((time * 3 + node.id.hashCode % 10 / 10) % 1) > 0.45;
    canvas.drawCircle(
      at(front.translate(-6 * zoom, -4 * zoom), lift: boxHeight * 0.45),
      2.2 * zoom,
      Paint()
        ..color = ledOn ? AppColors.secondaryGreenAccent : Colors.white.withValues(alpha: 0.35),
    );

    // Device icon floating just above the top face
    _paintIcon(
      canvas,
      style.icon,
      top.translate(0, -10 * zoom),
      16 * zoom,
      Colors.white,
      shadow: style.accent,
    );
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color, {
    Color? shadow,
  }) {
    if (shadow != null) {
      canvas.drawCircle(center, size * 0.78, Paint()..color = shadow.withValues(alpha: 0.9));
      canvas.drawCircle(
        center,
        size * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Compact name tag under a device.
  ///
  /// Only the device name is shown by default — printing every IP made the
  /// floor unreadable as soon as two devices sat close together. The address
  /// appears for the device you selected and for the packet's endpoints, and
  /// always in the inspector panel.
  void _paintPlate(
    Canvas canvas,
    NetworkNode node,
    Offset base,
    double zoom, {
    required bool showIp,
  }) {
    final center = base.translate(0, 16 * zoom);
    final scale = zoom.clamp(0.85, 1.2);

    final label = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    TextPainter? ip;
    if (showIp) {
      ip = TextPainter(
        text: TextSpan(
          text: node.ipAddress,
          style: TextStyle(
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    final width = math.max(label.width, ip?.width ?? 0) + 10;
    final height = label.height + (ip?.height ?? 0) + 4;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      rect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = showIp ? AppColors.primaryBlue.withValues(alpha: 0.35) : AppColors.cardBorder,
    );

    label.paint(canvas, Offset(center.dx - label.width / 2, rect.top + 2));
    ip?.paint(canvas, Offset(center.dx - ip.width / 2, rect.top + 2 + label.height));
  }

  // ─── Packet ───

  void _paintPacket(Canvas canvas, IsoProjection p) {
    if (packetProgress < 0 || activePath.length < 2) return;

    final maxHop = (activePath.length - 1).toDouble();
    final clamped = packetProgress.clamp(0.0, maxHop);
    final index = clamped.floor().clamp(0, activePath.length - 2);
    final local = clamped - index;

    final fromNode = _nodeById(activePath[index]);
    final toNode = _nodeById(activePath[index + 1]);
    if (fromNode == null || toNode == null) return;

    final a = p.project(fromNode.x, fromNode.y);
    final b = p.project(toNode.x, toNode.y);
    final ground = Offset.lerp(a, b, local)!;

    // Packets hop in a small arc rather than sliding flatly along the floor.
    final arc = math.sin(local * math.pi) * 26 * camera.zoom;
    final pos = ground.translate(0, -18 * camera.zoom - arc);

    // Shadow tracking underneath
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: 16 * camera.zoom, height: 7 * camera.zoom),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Trail
    for (var i = 1; i <= 4; i++) {
      final t = (clamped - i * 0.06).clamp(0.0, maxHop);
      final ti = t.floor().clamp(0, activePath.length - 2);
      final tl = t - ti;
      final fa = _nodeById(activePath[ti]);
      final fb = _nodeById(activePath[ti + 1]);
      if (fa == null || fb == null) continue;
      final gp = Offset.lerp(p.project(fa.x, fa.y), p.project(fb.x, fb.y), tl)!;
      final trailArc = math.sin(tl * math.pi) * 26 * camera.zoom;
      canvas.drawCircle(
        gp.translate(0, -18 * camera.zoom - trailArc),
        (7 - i) * 0.9 * camera.zoom,
        Paint()..color = AppColors.accentOrangeGold.withValues(alpha: 0.30 - i * 0.06),
      );
    }

    canvas.drawCircle(
      pos,
      14 * camera.zoom,
      Paint()..color = AppColors.accentOrange.withValues(alpha: 0.22),
    );
    canvas.drawCircle(pos, 7.5 * camera.zoom, Paint()..color = AppColors.accentOrange);
    canvas.drawCircle(
      pos.translate(-2 * camera.zoom, -2 * camera.zoom),
      2.6 * camera.zoom,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  NetworkNode? _nodeById(String id) {
    for (final n in simulation.nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  bool _isOnActivePath(String a, String b) {
    for (var i = 0; i < activePath.length - 1; i++) {
      if ((activePath[i] == a && activePath[i + 1] == b) ||
          (activePath[i] == b && activePath[i + 1] == a)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant IsoScenePainter old) => true;
}

/// Finds the device under a tap, using the same projection the painter uses.
NetworkNode? hitTestNode({
  required Offset localPosition,
  required SimulationModel simulation,
  required Size size,
  required IsoCamera camera,
}) {
  final p = IsoProjection(size: size, camera: camera);
  NetworkNode? best;
  var bestDistance = double.infinity;

  for (final node in simulation.nodes) {
    final base = p.project(node.x, node.y);
    final style = _styleFor(node.type);
    // Aim at the middle of the box body, not the floor point.
    final center = base.translate(0, -style.height * camera.zoom * 0.5);
    final d = (localPosition - center).distance;
    if (d < 34 * camera.zoom && d < bestDistance) {
      best = node;
      bestDistance = d;
    }
  }
  return best;
}
