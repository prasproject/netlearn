import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/header_back_button.dart';
import '../../data/models/simulation_model.dart';
import '../../domain/providers/simulation_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';
import 'simulation_tutorial_panel.dart';

/// Interactive network simulation screen with drag-drop nodes and packet animation.
class SimulationScreen extends ConsumerWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(simulationProvider);
    return Scaffold(
      body: Column(
        children: [
          // Green Header
          Container(
            decoration: const BoxDecoration(color: AppColors.secondaryGreen),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const HeaderBackButton(),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Simulasi Jaringan', style: AppTextStyles.sectionTitle)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Interaktif',
                            style: AppTextStyles.labelTiny.copyWith(color: AppColors.secondaryGreenAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sim.allSimulations.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final s = sim.allSimulations[index];
                          final isSelected = s.id == sim.simulation.id;
                          return GestureDetector(
                            onTap: () {
                              ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                              ref.read(simulationProvider.notifier).setSimulation(s.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Center(
                                child: Text(s.title, style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected ? AppColors.secondaryGreen : Colors.white,
                                )),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(sim.simulation.task, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: AppColors.secondaryGreenSurface,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Connection lines
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _ConnectionPainter(
                          sim.simulation,
                          sim.selectedPath,
                        ),
                      ),
                      // Packet animation
                      if (sim.packetProgress >= 0 && sim.packetProgress < sim.selectedPath.length)
                        _buildPacket(sim, constraints),
                      // Nodes
                      ...sim.simulation.nodes.map((node) => _buildNode(context, ref, sim, node, constraints)),
                      // Status bar
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sim.statusMessage, style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryGreen, fontWeight: FontWeight.w700)),
                              if (sim.detailMessage != null) ...[
                                const SizedBox(height: 2),
                                Text(sim.detailMessage!, style: AppTextStyles.labelSmall),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: sim.isAnimating ? 'Mengirim...' : 'Kirim Paket',
                        backgroundColor: AppColors.secondaryGreen,
                        shadowColor: AppColors.secondaryGreenDark,
                        onPressed: sim.isAnimating ? null : () {
                          ref.read(audioProvider.notifier).playSfx(SoundEffect.packetSend);
                          ref.read(simulationProvider.notifier).sendPacket().then((success) {
                            if (!success) return;
                            ref.read(audioProvider.notifier).playSfx(SoundEffect.packetArrive);
                            ref.read(progressProvider.notifier).completeSimulation();
                          });
                        },
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _controlIconButton(
                      icon: Icons.shuffle_rounded,
                      onTap: () {
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                        ref.read(simulationProvider.notifier).togglePath();
                      },
                    ),
                    const SizedBox(width: 8),
                    _controlIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                        ref.read(simulationProvider.notifier).reset();
                      },
                    ),
                    const SizedBox(width: 8),
                    _controlIconButton(
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                        SimulationTutorialPanel.showPopup(context, sim.simulation.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tombol acak (shuffle) untuk ganti rute',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryGreenSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondaryGreenAccent, width: 1.5),
        ),
        child: Icon(icon, color: AppColors.secondaryGreen, size: 20),
      ),
    );
  }

  Widget _buildNode(BuildContext context, WidgetRef ref, SimulationState sim, NetworkNode node, BoxConstraints constraints) {
    final colors = _nodeColors(node.type);
    final isConnectStart = sim.connectStartNodeId == node.id;
    return Positioned(
      left: node.x * constraints.maxWidth,
      top: node.y * constraints.maxHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          final dx = details.delta.dx / constraints.maxWidth;
          final dy = details.delta.dy / constraints.maxHeight;
          ref.read(simulationProvider.notifier).moveNode(node.id, dx, dy);
        },
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: colors.$1, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isConnectStart ? AppColors.accentOrange : colors.$2, width: isConnectStart ? 3 : 2),
              ),
              child: Icon(_nodeIcon(node.type), color: colors.$2, size: 22),
            ),
            const SizedBox(height: 3),
            Text(node.label, style: AppTextStyles.labelTiny.copyWith(color: AppColors.secondaryGreen, fontWeight: FontWeight.w800)),
            Text(node.ipAddress, style: AppTextStyles.statLabel.copyWith(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPacket(SimulationState sim, BoxConstraints constraints) {
    final nodeId = sim.selectedPath[sim.packetProgress];
    final nodeList = sim.simulation.nodes.where((n) => n.id == nodeId).toList();
    if (nodeList.isEmpty) return const SizedBox();
    final node = nodeList.first;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      left: node.x * constraints.maxWidth + 16,
      top: node.y * constraints.maxHeight - 8,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: AppColors.accentOrange,
          boxShadow: [BoxShadow(color: AppColors.accentOrange.withValues(alpha: 0.4), blurRadius: 8)],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 500.ms),
    );
  }

  (Color, Color) _nodeColors(NodeType type) => switch (type) {
    NodeType.pc => (AppColors.primaryBlueSurface, AppColors.primaryBlueLight),
    NodeType.router => (AppColors.secondaryGreenSurface, AppColors.secondaryGreenLight),
    NodeType.switchDevice => (AppColors.secondaryGreenSurface, AppColors.secondaryGreenLight),
    NodeType.server => (AppColors.accentOrangeSurface, AppColors.accentOrange),
  };

  IconData _nodeIcon(NodeType type) => switch (type) {
    NodeType.pc => Icons.computer_rounded,
    NodeType.router => Icons.router_rounded,
    NodeType.switchDevice => Icons.device_hub_rounded,
    NodeType.server => Icons.dns_rounded,
  };
}

class _ConnectionPainter extends CustomPainter {
  final SimulationModel simulation;
  final List<String> selectedPath;
  _ConnectionPainter(this.simulation, this.selectedPath);

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in simulation.connections) {
      final fromList = simulation.nodes.where((n) => n.id == conn.fromNodeId).toList();
      final toList = simulation.nodes.where((n) => n.id == conn.toNodeId).toList();
      if (fromList.isEmpty || toList.isEmpty) continue;
      
      final from = fromList.first;
      final to = toList.first;

      final isOnPath = _isConnectionOnPath(conn.fromNodeId, conn.toNodeId);
      final paint = Paint()
        ..color = isOnPath ? AppColors.secondaryGreenAccent : Colors.grey.shade300
        ..strokeWidth = isOnPath ? 2.7 : 1.6
        ..style = PaintingStyle.stroke;

      final startX = from.x * size.width + 22;
      final startY = from.y * size.height + 22;
      final endX = to.x * size.width + 22;
      final endY = to.y * size.height + 22;

      final path = Path()..moveTo(startX, startY)..lineTo(endX, endY);
      
      const dashWidth = 6.0;
      const dashSpace = 3.0;
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0;
        while (distance < metric.length) {
          final len = (distance + dashWidth).clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(distance, len), paint);
          distance += dashWidth + dashSpace;
        }
      }
    }
  }

  bool _isConnectionOnPath(String fromId, String toId) {
    for (int i = 0; i < selectedPath.length - 1; i++) {
      if ((selectedPath[i] == fromId && selectedPath[i + 1] == toId) ||
          (selectedPath[i] == toId && selectedPath[i + 1] == fromId)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) => true;
}
