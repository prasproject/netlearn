import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/header_back_button.dart';
import '../../core/widgets/loading_views.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/simulation_model.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/simulation_provider.dart';
import 'iso_canvas.dart';
import 'simulation_missions.dart';
import 'simulation_tutorial_panel.dart';

/// Interactive 2.5D network simulation.
///
/// The routing engine (cables, IP rules, BFS path finding) already lived in
/// `SimulationNotifier`; most of it had no controls in the UI at all. This
/// screen exposes the whole toolset on an isometric canvas the student can
/// pan, zoom, and rotate, with a guided mission list that ticks itself off.
class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> with TickerProviderStateMixin {
  // Idle clock driving blinking LEDs, flowing link dots and pulsing rings.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  IsoCamera _camera = const IsoCamera();
  MissionStats _stats = const MissionStats();

  String? _selectedNodeId;
  bool _cableArmed = false;
  bool _showGrid = true;
  bool _missionsOpen = true;
  int _dockTab = 0;

  // Gesture bookkeeping
  String? _draggingNodeId;
  IsoCamera _gestureStartCamera = const IsoCamera();
  Size _canvasSize = Size.zero;

  final _ipController = TextEditingController();

  @override
  void dispose() {
    _clock.dispose();
    _ipController.dispose();
    super.dispose();
  }

  bool get _isPlayground => ref.read(simulationProvider).simulation.id == 'sim-playground';

  // ─── Mission tracking ───

  void _watchForMissionProgress() {
    ref.listen<SimulationState>(simulationProvider, (previous, next) {
      if (previous == null) return;
      var stats = _stats;

      if (next.simulation.nodes.length > previous.simulation.nodes.length) {
        stats = stats.copyWith(devicesAdded: stats.devicesAdded + 1);
      }
      if (next.simulation.connections.length > previous.simulation.connections.length) {
        stats = stats.copyWith(
          linksCreated: stats.linksCreated + 1,
          cablesUsed: {...stats.cablesUsed, next.activeCableType},
        );
      }
      // A finished send reports success in the status line.
      final finished = previous.isAnimating && !next.isAnimating;
      if (finished && next.statusMessage.contains('✓')) {
        stats = stats.copyWith(successfulSends: stats.successfulSends + 1);
        ref.read(progressProvider.notifier).completeSimulation();
      }
      if (next.selectedPath.join() != previous.selectedPath.join() &&
          !next.isAnimating &&
          next.simulation.id == previous.simulation.id) {
        stats = stats.copyWith(routeChanges: stats.routeChanges + 1);
      }
      if (next.simulation.id != previous.simulation.id) {
        // A new scenario starts its own walkthrough.
        stats = const MissionStats();
        _selectedNodeId = null;
        _camera = const IsoCamera();
      }

      if (stats != _stats) setState(() => _stats = stats);
    });
  }

  List<SimMission> get _missions =>
      SimulationMissions.forSimulation(ref.read(simulationProvider).simulation.id);

  int get _currentMissionIndex {
    final state = ref.read(simulationProvider);
    final missions = _missions;
    for (var i = 0; i < missions.length; i++) {
      if (!missions[i].isDone(state, _stats)) return i;
    }
    return missions.length;
  }

  // ─── Gestures ───

  void _onScaleStart(ScaleStartDetails details) {
    final sim = ref.read(simulationProvider);
    _gestureStartCamera = _camera;

    if (details.pointerCount == 1) {
      final node = hitTestNode(
        localPosition: details.localFocalPoint,
        simulation: sim.simulation,
        size: _canvasSize,
        camera: _camera,
      );
      _draggingNodeId = node?.id;
      return;
    }
    _draggingNodeId = null;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_draggingNodeId != null && details.pointerCount == 1) {
      // Dragging a device follows the finger along the tilted floor.
      final projection = IsoProjection(size: _canvasSize, camera: _camera);
      final delta = projection.unprojectDelta(details.focalPointDelta);
      ref.read(simulationProvider.notifier).moveNode(_draggingNodeId!, delta.dx, delta.dy);
      _markViewExplored();
      return;
    }

    setState(() {
      _camera = _camera.copyWith(
        pan: _camera.pan + details.focalPointDelta,
        zoom: _gestureStartCamera.zoom * details.scale,
        rotation: _gestureStartCamera.rotation + details.rotation,
      );
    });
    _markViewExplored();
  }

  void _onTapUp(TapUpDetails details) {
    final sim = ref.read(simulationProvider);
    final node = hitTestNode(
      localPosition: details.localPosition,
      simulation: sim.simulation,
      size: _canvasSize,
      camera: _camera,
    );

    if (node == null) {
      setState(() => _selectedNodeId = null);
      return;
    }

    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
    setState(() {
      _selectedNodeId = node.id;
      _ipController.text = node.ipAddress;
      _stats = _stats.copyWith(nodesInspected: _stats.nodesInspected + 1);
    });

    if (_cableArmed) {
      ref.read(simulationProvider.notifier).handleNodeTap(node.id);
    }
  }

  void _nudgeCamera({double rotate = 0, double zoom = 1}) {
    setState(() {
      _camera = _camera.copyWith(rotation: _camera.rotation + rotate, zoom: _camera.zoom * zoom);
    });
    _markViewExplored();
  }

  /// Anything that counts as "looking around the network": panning, zooming,
  /// rotating, toggling the floor grid, recentring, or dragging a device.
  ///
  /// The first guided step used to accept only a pan/zoom gesture, which on a
  /// desktop browser was easy to miss entirely — a mouse drag usually grabs a
  /// device instead, and the wheel did nothing — so the checklist could sit on
  /// step 1 forever.
  void _markViewExplored() {
    if (_stats.cameraMoved) return;
    setState(() => _stats = _stats.copyWith(cameraMoved: true));
  }

  /// Mouse-wheel / trackpad zoom, so the canvas behaves like a map in the web
  /// build where there is no pinch gesture.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final factor = event.scrollDelta.dy > 0 ? 0.92 : 1.08;
    setState(() => _camera = _camera.copyWith(zoom: _camera.zoom * factor));
    _markViewExplored();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    _watchForMissionProgress();
    final sim = ref.watch(simulationProvider);

    if (!sim.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoader(message: 'Menyiapkan simulasi...', color: AppColors.secondaryGreen),
      );
    }

    final selected = _selectedNodeId == null
        ? null
        : sim.simulation.nodes
              .where((n) => n.id == _selectedNodeId)
              .cast<NetworkNode?>()
              .firstWhere((n) => true, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(sim),
          _guidePanel(sim),
          Expanded(child: _canvas(sim)),
          if (selected != null) _inspector(sim, selected),
          _dock(sim),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _header(SimulationState sim) {
    return Container(
      decoration: BoxDecoration(color: AppColors.secondaryGreen, boxShadow: AppShadows.card),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  const HeaderBackButton(),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Simulasi Jaringan', style: AppTextStyles.sectionTitle)),
                  Pressable(
                    onTap: () => SimulationTutorialPanel.showPopup(context, sim.simulation.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'Petunjuk',
                            style: AppTextStyles.labelTiny.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sim.allSimulations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final s = sim.allSimulations[index];
                    final isSelected = s.id == sim.simulation.id;
                    return Pressable(
                      onTap: () {
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                        ref.read(simulationProvider.notifier).setSimulation(s.id);
                        setState(() {
                          _selectedNodeId = null;
                          _cableArmed = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            if (s.id == 'sim-playground') ...[
                              Icon(
                                Icons.science_rounded,
                                size: 13,
                                color: isSelected ? AppColors.secondaryGreen : Colors.white,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              s.title,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSelected ? AppColors.secondaryGreen : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Canvas ───

  Widget _canvas(SimulationState sim) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: (_) => _draggingNodeId = null,
                    onTapUp: _onTapUp,
                    child: AnimatedBuilder(
                      animation: _clock,
                      builder: (context, _) {
                        // The packet slides smoothly between hops instead of
                        // teleporting when the notifier advances a step.
                        return TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: sim.packetProgress.toDouble(),
                            end: sim.packetProgress.toDouble(),
                          ),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeInOut,
                          builder: (context, packet, __) => CustomPaint(
                            size: _canvasSize,
                            painter: IsoScenePainter(
                              simulation: sim.simulation,
                              camera: _camera,
                              cableByLinkKey: sim.cableByLinkKey,
                              activePath: sim.selectedPath,
                              packetProgress: sim.packetProgress < 0 ? -1 : packet,
                              time: _clock.value,
                              selectedNodeId: _selectedNodeId,
                              connectStartNodeId: sim.connectStartNodeId,
                              sourceNodeId: sim.packetSourceNodeId,
                              targetNodeId: sim.packetTargetNodeId,
                              showGrid: _showGrid,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // The status bar is purely informational (no tap target of its
              // own), so it must come BEFORE the camera buttons in the Stack.
              // On a short canvas the two can overlap geometrically, and a
              // later Stack child wins hit-testing regardless of whether it
              // actually handles the tap — with the old order, the status bar
              // silently swallowed taps meant for the camera buttons whenever
              // that overlap happened, making them dead with no visible cause.
              Positioned(left: 12, right: 12, bottom: 12, child: _statusBar(sim)),
              Positioned(right: 12, top: 12, child: _cameraTools()),
            ],
          ),
        );
      },
    );
  }

  Widget _cameraTools() {
    Widget tool(IconData icon, VoidCallback onTap, {String? tooltip}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: tooltip ?? '',
          child: Pressable(
            onTap: onTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Icon(icon, size: 18, color: AppColors.secondaryGreen),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        tool(Icons.rotate_left_rounded, () => _nudgeCamera(rotate: -0.35), tooltip: 'Putar kiri'),
        tool(Icons.rotate_right_rounded, () => _nudgeCamera(rotate: 0.35), tooltip: 'Putar kanan'),
        tool(Icons.zoom_in_rounded, () => _nudgeCamera(zoom: 1.2), tooltip: 'Perbesar'),
        tool(Icons.zoom_out_rounded, () => _nudgeCamera(zoom: 0.83), tooltip: 'Perkecil'),
      ],
    );
  }

  // ─── Mission checklist ───

  /// Guide panel: the scenario's goal plus the current guided step, in one
  /// fixed place between the header and the canvas.
  ///
  /// This used to be two separate pieces — a goal banner, and a mission card
  /// that floated, semi-transparent, on top of the isometric scene. Reading
  /// instructions layered over a moving 3D drawing (and not knowing there was
  /// a second, different explanation elsewhere) was a big part of what made
  /// the guidance hard to follow. One panel, opaque, out of the canvas's way.
  Widget _guidePanel(SimulationState sim) {
    final missions = _missions;
    final index = _currentMissionIndex;
    final allDone = index >= missions.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: allDone ? AppColors.secondaryGreenLight : AppColors.secondaryGreenAccent,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded, size: 15, color: AppColors.secondaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sim.simulation.task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondaryGreenDark,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Pressable(
            onTap: () => setState(() => _missionsOpen = !_missionsOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: allDone
                          ? AppColors.goldSurface
                          : AppColors.secondaryGreenSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      allDone ? Icons.emoji_events_rounded : missions[index].icon,
                      size: 15,
                      color: allDone ? AppColors.goldDark : AppColors.secondaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allDone
                              ? 'Semua langkah selesai 🎉'
                              : 'Langkah ${index + 1} dari ${missions.length}',
                          style: AppTextStyles.labelTiny.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!allDone)
                          Text(
                            missions[index].title,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _missionsOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppMotion.normal,
            crossFadeState: _missionsOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!allDone) ...[
                    Text(
                      missions[index].hint,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Pressable(
                      onTap: () => _openTab(missions[index].tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryGreen,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Flexible: a long action label must not overflow
                            // the panel on a narrow phone.
                            Flexible(
                              child: Text(
                                missions[index].action,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'Kamu sudah mencoba seluruh alur simulasi ini. Coba topologi lain, '
                      'atau rancang jaringanmu sendiri di Lab Bebas.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < missions.length; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: AppMotion.normal,
                            height: 5,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: missions[i].isDone(sim, _stats)
                                  ? AppColors.secondaryGreenLight
                                  : AppColors.divider,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.normal);
  }

  /// Jump to the controls a mission refers to.
  void _openTab(SimDockTab tab) {
    if (tab == SimDockTab.canvas) {
      // Nothing to open — the action happens on the canvas itself.
      setState(() => _missionsOpen = true);
      return;
    }
    final index = switch (tab) {
      SimDockTab.build => _isPlayground ? 0 : 0,
      SimDockTab.send => _isPlayground ? 1 : 0,
      SimDockTab.layout => _isPlayground ? 2 : 1,
      SimDockTab.canvas => _dockTab,
    };
    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
    setState(() => _dockTab = index);
  }

  // ─── Status ───

  Widget _statusBar(SimulationState sim) {
    final isError = sim.statusMessage.toLowerCase().contains('gagal');
    final isSuccess = sim.statusMessage.contains('✓');
    final color = isError
        ? AppColors.error
        : isSuccess
        ? AppColors.secondaryGreen
        : AppColors.textSecondary;

    return AnimatedContainer(
      key: const Key('simStatusBar'),
      duration: AppMotion.normal,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isSuccess
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sim.statusMessage,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (sim.detailMessage != null)
                  Text(
                    sim.detailMessage!,
                    style: AppTextStyles.labelTiny.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Node inspector ───

  Widget _inspector(SimulationState sim, NetworkNode node) {
    final isSource = sim.packetSourceNodeId == node.id;
    final isTarget = sim.packetTargetNodeId == node.id;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(node.type), size: 18, color: AppColors.secondaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${node.label} · ${_typeLabel(node.type)}',
                  style: AppTextStyles.cardTitleDark,
                ),
              ),
              Pressable(
                onTap: () => setState(() => _selectedNodeId = null),
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _ipController,
                    style: AppTextStyles.bodySmall,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Alamat IP',
                      labelStyle: AppTextStyles.labelTiny,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (_) => _saveIp(node),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => _saveIp(node),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Simpan', style: AppTextStyles.buttonSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chipButton(
                  label: isSource ? 'Pengirim ✓' : 'Jadikan pengirim',
                  color: AppColors.primaryBlue,
                  active: isSource,
                  onTap: () =>
                      ref.read(simulationProvider.notifier).setPacketEndpoints(sourceId: node.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipButton(
                  label: isTarget ? 'Tujuan ✓' : 'Jadikan tujuan',
                  color: AppColors.accentOrange,
                  active: isTarget,
                  onTap: () =>
                      ref.read(simulationProvider.notifier).setPacketEndpoints(targetId: node.id),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.fast).slideY(begin: 0.15);
  }

  void _saveIp(NetworkNode node) {
    final value = _ipController.text.trim();
    if (value.isEmpty || value == node.ipAddress) return;
    ref.read(simulationProvider.notifier).updateNodeIp(node.id, value);
    setState(() => _stats = _stats.copyWith(ipEdits: _stats.ipEdits + 1));
    FocusScope.of(context).unfocus();
  }

  Widget _chipButton({
    required String label,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? Colors.white : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom dock ───

  static const _dockIcons = [
    Icons.construction_rounded,
    Icons.send_rounded,
    Icons.visibility_rounded,
  ];

  Widget _dock(SimulationState sim) {
    final tabs = _isPlayground
        ? const ['Bangun', 'Kirim', 'Tampilan']
        : const ['Kirim Paket', 'Tampilan'];
    // The build tab only exists in the free-build lab, so the fixed
    // topologies' tabs borrow the send/view icons rather than the full set.
    final icons = _isPlayground ? _dockIcons : _dockIcons.sublist(1);
    final tab = _dockTab.clamp(0, tabs.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.overlay,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              // Segmented control, not a bottom nav bar: it switches which
              // toolset is showing below, it doesn't change screens. Icons
              // make that legible at a glance instead of relying on reading
              // short, easy-to-skim-past text pills.
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: Pressable(
                        onTap: () {
                          if (i == tab) return;
                          ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                          setState(() => _dockTab = i);
                        },
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: i == tab
                                ? AppColors.secondaryGreen
                                : AppColors.secondaryGreenSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[i],
                                size: 17,
                                color: i == tab ? Colors.white : AppColors.secondaryGreen,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tabs[i],
                                style: AppTextStyles.labelTiny.copyWith(
                                  color: i == tab ? Colors.white : AppColors.secondaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.enter,
                child: _isPlayground
                    ? switch (tab) {
                        0 => _buildTools(sim),
                        1 => _sendTools(sim),
                        _ => _layoutTools(sim),
                      }
                    : switch (tab) {
                        0 => _sendTools(sim),
                        _ => _layoutTools(sim),
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTools(SimulationState sim) {
    return Column(
      key: const ValueKey('build'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabHint(
          'Susun jaringanmu: tambahkan perangkat, lalu pilih kabel dan ketuk '
          'dua perangkat untuk menyambungkannya.',
        ),
        Text('Tambah perangkat', style: AppTextStyles.labelTiny),
        const SizedBox(height: 6),
        Row(
          children: [
            _toolChip(
              Icons.computer_rounded,
              'PC',
              AppColors.primaryBlue,
              () => _addNode(NodeType.pc),
            ),
            _toolChip(
              Icons.device_hub_rounded,
              'Switch',
              AppColors.purple,
              () => _addNode(NodeType.switchDevice),
            ),
            _toolChip(
              Icons.router_rounded,
              'Router',
              AppColors.secondaryGreen,
              () => _addNode(NodeType.router),
            ),
            _toolChip(
              Icons.dns_rounded,
              'Server',
              AppColors.accentOrange,
              () => _addNode(NodeType.server),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Kabel', style: AppTextStyles.labelTiny),
            const SizedBox(width: 8),
            if (_cableArmed)
              Text(
                sim.connectStartNodeId == null
                    ? '— ketuk perangkat pertama'
                    : '— ketuk perangkat kedua',
                style: AppTextStyles.labelTiny.copyWith(color: AppColors.accentOrange),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final type in CableType.values)
              Expanded(
                child: Pressable(
                  onTap: () {
                    ref.read(simulationProvider.notifier).setCableType(type);
                    setState(() => _cableArmed = true);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _cableArmed && sim.activeCableType == type
                          ? cableColor(type)
                          : cableColor(type).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cableColor(type).withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        _cableLabel(type),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _cableArmed && sim.activeCableType == type
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Pressable(
              onTap: () => setState(() => _cableArmed = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.postSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pan_tool_alt_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sendTools(SimulationState sim) {
    final source = _labelOf(sim, sim.packetSourceNodeId);
    final target = _labelOf(sim, sim.packetTargetNodeId);

    return Column(
      key: const ValueKey('send'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabHint(
          _isPlayground
              ? 'Tentukan pengirim dan tujuan, lalu kirim paket. Kalau gagal, '
                    'pesan di kanvas menjelaskan sebabnya.'
              : 'Kabel yang menyala tebal adalah rute yang akan dilewati paket. '
                    'Ganti rute dengan tombol acak, lalu tekan Kirim Paket.',
        ),
        if (_isPlayground) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pengirim: $source  →  Tujuan: $target',
                  style: AppTextStyles.labelTiny.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk perangkat di kanvas untuk mengganti pengirim/tujuan.',
            style: AppTextStyles.labelTiny.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: sim.isAnimating ? 'Mengirim...' : 'Kirim Paket',
                icon: Icons.send_rounded,
                backgroundColor: AppColors.secondaryGreen,
                shadowColor: AppColors.secondaryGreenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: sim.isAnimating ? null : _sendPacket,
              ),
            ),
            if (!_isPlayground) ...[
              const SizedBox(width: 8),
              _iconButton(Icons.shuffle_rounded, 'Rute', () {
                ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                ref.read(simulationProvider.notifier).togglePath();
              }),
            ],
            const SizedBox(width: 8),
            _iconButton(Icons.refresh_rounded, 'Ulangi', () {
              ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
              ref.read(simulationProvider.notifier).reset();
            }),
          ],
        ),
      ],
    );
  }

  Widget _layoutTools(SimulationState sim) {
    return Column(
      key: const ValueKey('layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabHint('Atur sudut pandang kanvas supaya jaringan lebih mudah dibaca.'),
        Text(
          'Seret perangkat di kanvas untuk memindahkannya. Cubit untuk memperbesar, '
          'putar dengan dua jari, atau pakai tombol di kanan kanvas.',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _chipButton(
                label: _showGrid ? 'Sembunyikan garis' : 'Tampilkan garis',
                color: AppColors.secondaryGreen,
                active: _showGrid,
                onTap: () {
                  setState(() => _showGrid = !_showGrid);
                  _markViewExplored();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _chipButton(
                label: 'Kembalikan tampilan',
                color: AppColors.primaryBlue,
                active: false,
                onTap: () {
                  setState(() => _camera = const IsoCamera());
                  _markViewExplored();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.accentOrangeLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelTiny.copyWith(color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.labelTiny.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onTap) {
    // Labelled, not tooltip-only: on a touch screen a tooltip never appears,
    // so the shuffle and reset buttons read as mystery icons.
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondaryGreenSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondaryGreenAccent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.secondaryGreen, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelTiny.copyWith(
                color: AppColors.secondaryGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNode(NodeType type) {
    ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
    ref.read(simulationProvider.notifier).addNode(type);
  }

  Future<void> _sendPacket() async {
    ref.read(audioProvider.notifier).playSfx(SoundEffect.packetSend);
    setState(() => _stats = _stats.copyWith(sendAttempts: _stats.sendAttempts + 1));
    final success = await ref.read(simulationProvider.notifier).sendPacket();
    if (!mounted) return;
    ref
        .read(audioProvider.notifier)
        .playSfx(success ? SoundEffect.packetArrive : SoundEffect.incorrect);
  }

  String _labelOf(SimulationState sim, String? nodeId) {
    if (nodeId == null) return '—';
    for (final n in sim.simulation.nodes) {
      if (n.id == nodeId) return n.label;
    }
    return '—';
  }

  String _cableLabel(CableType type) => switch (type) {
    CableType.straight => 'Straight',
    CableType.cross => 'Cross',
    CableType.wifi => 'WiFi',
  };

  String _typeLabel(NodeType type) => switch (type) {
    NodeType.pc => 'PC',
    NodeType.router => 'Router',
    NodeType.switchDevice => 'Switch',
    NodeType.server => 'Server',
  };

  IconData _iconFor(NodeType type) => switch (type) {
    NodeType.pc => Icons.computer_rounded,
    NodeType.router => Icons.router_rounded,
    NodeType.switchDevice => Icons.device_hub_rounded,
    NodeType.server => Icons.dns_rounded,
  };
}
