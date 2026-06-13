import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/simulation_model.dart';
import '../../data/repositories/simulation_repository.dart';
import 'repository_providers.dart';

enum CableType { straight, cross, wifi }

/// Simulation state
class SimulationState {
  static const _unset = Object();
  final SimulationModel simulation;
  final List<SimulationModel> allSimulations;
  final List<String> selectedPath;
  final int packetProgress; // -1 = idle, 0..n = current path index
  final bool isAnimating;
  final String statusMessage;
  final String? detailMessage;
  final bool isLoaded;
  final CableType activeCableType;
  final String? connectStartNodeId;
  final String? packetSourceNodeId;
  final String? packetTargetNodeId;
  final Map<String, CableType> cableByLinkKey;
  final int pcCount;
  final int switchCount;
  final int routerCount;

  SimulationState({
    required this.simulation,
    this.allSimulations = const [],
    this.selectedPath = const [],
    this.packetProgress = -1,
    this.isAnimating = false,
    this.statusMessage = 'Siap mengirim paket',
    this.detailMessage,
    this.isLoaded = false,
    this.activeCableType = CableType.straight,
    this.connectStartNodeId,
    this.packetSourceNodeId,
    this.packetTargetNodeId,
    this.cableByLinkKey = const {},
    this.pcCount = 0,
    this.switchCount = 0,
    this.routerCount = 0,
  });

  SimulationState copyWith({
    SimulationModel? simulation,
    List<SimulationModel>? allSimulations,
    List<String>? selectedPath,
    int? packetProgress,
    bool? isAnimating,
    String? statusMessage,
    Object? detailMessage = _unset,
    bool? isLoaded,
    CableType? activeCableType,
    Object? connectStartNodeId = _unset,
    Object? packetSourceNodeId = _unset,
    Object? packetTargetNodeId = _unset,
    Map<String, CableType>? cableByLinkKey,
    int? pcCount,
    int? switchCount,
    int? routerCount,
  }) {
    return SimulationState(
      simulation: simulation ?? this.simulation,
      allSimulations: allSimulations ?? this.allSimulations,
      selectedPath: selectedPath ?? this.selectedPath,
      packetProgress: packetProgress ?? this.packetProgress,
      isAnimating: isAnimating ?? this.isAnimating,
      statusMessage: statusMessage ?? this.statusMessage,
      detailMessage: identical(detailMessage, _unset) ? this.detailMessage : detailMessage as String?,
      isLoaded: isLoaded ?? this.isLoaded,
      activeCableType: activeCableType ?? this.activeCableType,
      connectStartNodeId: identical(connectStartNodeId, _unset) ? this.connectStartNodeId : connectStartNodeId as String?,
      packetSourceNodeId: identical(packetSourceNodeId, _unset) ? this.packetSourceNodeId : packetSourceNodeId as String?,
      packetTargetNodeId: identical(packetTargetNodeId, _unset) ? this.packetTargetNodeId : packetTargetNodeId as String?,
      cableByLinkKey: cableByLinkKey ?? this.cableByLinkKey,
      pcCount: pcCount ?? this.pcCount,
      switchCount: switchCount ?? this.switchCount,
      routerCount: routerCount ?? this.routerCount,
    );
  }
}

class SimulationNotifier extends StateNotifier<SimulationState> {
  final SimulationRepository _repo;

  SimulationNotifier(this._repo) : super(SimulationState(
    simulation: SimulationModel(
      id: 'loading', title: '', description: '', task: '',
      nodes: [], connections: [], scenarios: [],
    ),
  )) {
    _loadSimulation();
  }

  Future<void> _loadSimulation() async {
    final sims = await _repo.getAllSimulations();
    if (sims.isEmpty) return;
    final sim = sims.first;
    final scenario = sim.scenarios.isNotEmpty ? sim.scenarios.first : null;
    state = SimulationState(
      simulation: sim,
      allSimulations: sims,
      selectedPath: scenario?.correctPath ?? [],
      isLoaded: true,
      pcCount: sim.nodes.where((n) => n.type == NodeType.pc).length,
      switchCount: sim.nodes.where((n) => n.type == NodeType.switchDevice).length,
      routerCount: sim.nodes.where((n) => n.type == NodeType.router).length,
    );
  }

  void setSimulation(String id) {
    if (state.isAnimating) return;
    final sim = state.allSimulations.firstWhere((s) => s.id == id, orElse: () => state.simulation);
    final scenario = sim.scenarios.isNotEmpty ? sim.scenarios.first : null;
    state = state.copyWith(
      simulation: sim,
      selectedPath: scenario?.correctPath ?? [],
      statusMessage: 'Siap mengirim paket',
      detailMessage: null,
      packetProgress: -1,
      connectStartNodeId: null,
      packetSourceNodeId: sim.nodes.where((n) => n.type == NodeType.pc).isNotEmpty
          ? sim.nodes.firstWhere((n) => n.type == NodeType.pc).id
          : null,
      packetTargetNodeId: sim.nodes.where((n) => n.type == NodeType.server || n.type == NodeType.pc).isNotEmpty
          ? sim.nodes.firstWhere((n) => n.type == NodeType.server || n.type == NodeType.pc).id
          : null,
      cableByLinkKey: {},
      pcCount: sim.nodes.where((n) => n.type == NodeType.pc).length,
      switchCount: sim.nodes.where((n) => n.type == NodeType.switchDevice).length,
      routerCount: sim.nodes.where((n) => n.type == NodeType.router).length,
    );
  }

  /// Select a route path
  void selectPath(List<String> path) {
    if (state.isAnimating) return;
    state = state.copyWith(
      selectedPath: path,
      statusMessage: 'Jalur dipilih: ${_pathLabel(path)}',
    );
  }

  /// Toggle between available paths
  void togglePath() {
    if (state.isAnimating || state.simulation.scenarios.isEmpty) return;
    
    // Find next scenario
    int currentIdx = state.simulation.scenarios.indexWhere(
      (s) => s.correctPath.join() == state.selectedPath.join()
    );
    int nextIdx = (currentIdx + 1) % state.simulation.scenarios.length;
    
    selectPath(state.simulation.scenarios[nextIdx].correctPath);
  }

  /// Send packet animation
  Future<bool> sendPacket() async {
    if (state.simulation.id == 'sim-playground') {
      return _sendPlaygroundPacket();
    }

    if (state.isAnimating || state.selectedPath.isEmpty) return false;

    state = state.copyWith(isAnimating: true, packetProgress: 0,
      statusMessage: 'Mengirim paket...');

    for (int i = 0; i < state.selectedPath.length; i++) {
      state = state.copyWith(packetProgress: i);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    final pathLabel = _pathLabel(state.selectedPath);
    final routeLabel = state.selectedPath.length > 1 && state.selectedPath[1] == 'router1'
        ? 'Router'
        : 'Switch';
    state = state.copyWith(
      isAnimating: false,
      packetProgress: state.selectedPath.length - 1,
      statusMessage: 'Status: Paket dikirim via $routeLabel ✓',
      detailMessage: 'Hop: ${state.selectedPath.length - 1} | Jalur: $pathLabel',
    );
    return true;
  }

  Future<bool> _sendPlaygroundPacket() async {
    if (state.isAnimating) return false;
    final sourceId = state.packetSourceNodeId;
    final targetId = state.packetTargetNodeId;
    if (sourceId == null || targetId == null || sourceId == targetId) {
      state = state.copyWith(
        statusMessage: 'Pilih source dan target yang berbeda',
        detailMessage: 'Tips: source dan target minimal 2 node berbeda.',
      );
      return false;
    }

    final path = _findPath(sourceId, targetId);
    if (path.isEmpty) {
      state = state.copyWith(
        selectedPath: [],
        packetProgress: -1,
        statusMessage: 'Gagal: tidak ada jalur koneksi',
        detailMessage: 'Buat koneksi dulu dengan mode kabel/wifi.',
      );
      return false;
    }

    final sourceNode = state.simulation.nodes.firstWhere((n) => n.id == sourceId);
    final targetNode = state.simulation.nodes.firstWhere((n) => n.id == targetId);
    final sourceIp = _parseIpv4(sourceNode.ipAddress);
    final targetIp = _parseIpv4(targetNode.ipAddress);
    if (sourceIp == null || targetIp == null) {
      state = state.copyWith(
        selectedPath: path,
        packetProgress: -1,
        statusMessage: 'Gagal: format IP tidak valid',
        detailMessage: 'Gunakan format IPv4, contoh 192.168.10.2',
      );
      return false;
    }

    final hasInvalidCable = _hasInvalidCable(path);
    if (hasInvalidCable) {
      state = state.copyWith(
        selectedPath: path,
        packetProgress: -1,
        statusMessage: 'Gagal: tipe kabel tidak cocok',
        detailMessage: 'Coba ganti straight/cross sesuai jenis perangkat.',
      );
      return false;
    }

    final sameSubnet = sourceIp[0] == targetIp[0] &&
        sourceIp[1] == targetIp[1] &&
        sourceIp[2] == targetIp[2];
    final hasRouter = path.any((id) {
      final node = state.simulation.nodes.firstWhere((n) => n.id == id);
      return node.type == NodeType.router;
    });
    final canRoute = sameSubnet || hasRouter;
    if (!canRoute) {
      state = state.copyWith(
        selectedPath: path,
        packetProgress: -1,
        statusMessage: 'Gagal: beda subnet tanpa router',
        detailMessage: 'Gunakan router atau samakan subnet /24.',
      );
      return false;
    }

    state = state.copyWith(
      isAnimating: true,
      selectedPath: path,
      packetProgress: 0,
      statusMessage: 'Mengirim paket playground...',
      detailMessage: 'Jalur: ${_pathLabel(path)}',
    );

    for (int i = 0; i < path.length; i++) {
      state = state.copyWith(packetProgress: i);
      await Future.delayed(const Duration(milliseconds: 550));
    }

    state = state.copyWith(
      isAnimating: false,
      packetProgress: path.length - 1,
      statusMessage: 'Sukses: paket terkirim ✓',
      detailMessage: 'Hop: ${path.length - 1} | Jalur: ${_pathLabel(path)}',
    );
    return true;
  }

  /// Reset simulation
  void reset() {
    final scenario = state.simulation.scenarios.isNotEmpty
        ? state.simulation.scenarios.first : null;
    state = state.copyWith(
      selectedPath: scenario?.correctPath ?? [],
      packetProgress: -1,
      isAnimating: false,
      statusMessage: 'Siap mengirim paket',
      detailMessage: null,
      isLoaded: true,
      connectStartNodeId: null,
    );
  }

  /// Move a node (drag-and-drop)
  void moveNode(String nodeId, double dx, double dy) {
    final nodes = state.simulation.nodes.map((n) {
      if (n.id == nodeId) {
        return n.copyWith(
          x: (n.x + dx).clamp(0.0, 0.85),
          y: (n.y + dy).clamp(0.0, 0.75),
        );
      }
      return n;
    }).toList();

    state = state.copyWith(
      simulation: SimulationModel(
        id: state.simulation.id,
        title: state.simulation.title,
        description: state.simulation.description,
        task: state.simulation.task,
        nodes: nodes,
        connections: state.simulation.connections,
        scenarios: state.simulation.scenarios,
      ),
    );
  }

  void setCableType(CableType type) {
    state = state.copyWith(activeCableType: type, connectStartNodeId: null);
  }

  void handleNodeTap(String nodeId) {
    if (state.simulation.id != 'sim-playground') return;
    if (state.connectStartNodeId == null) {
      state = state.copyWith(
        connectStartNodeId: nodeId,
        statusMessage: 'Pilih node kedua untuk koneksi ${state.activeCableType.name}',
      );
      return;
    }
    if (state.connectStartNodeId == nodeId) {
      state = state.copyWith(connectStartNodeId: null);
      return;
    }

    final start = state.connectStartNodeId!;
    final alreadyExists = state.simulation.connections.any((c) =>
        (c.fromNodeId == start && c.toNodeId == nodeId) ||
        (c.fromNodeId == nodeId && c.toNodeId == start));
    if (alreadyExists) {
      state = state.copyWith(
        connectStartNodeId: null,
        statusMessage: 'Koneksi sudah ada',
      );
      return;
    }

    final updatedConnections = [
      ...state.simulation.connections,
      NetworkConnection(fromNodeId: start, toNodeId: nodeId),
    ];
    final linkKey = _linkKey(start, nodeId);
    final updatedCable = {
      ...state.cableByLinkKey,
      linkKey: state.activeCableType,
    };

    state = state.copyWith(
      simulation: _copySim(connections: updatedConnections),
      cableByLinkKey: updatedCable,
      connectStartNodeId: null,
      statusMessage: 'Koneksi ${state.activeCableType.name} dibuat',
      detailMessage: null,
    );
  }

  void setPacketEndpoints({String? sourceId, String? targetId}) {
    state = state.copyWith(
      packetSourceNodeId: sourceId ?? state.packetSourceNodeId,
      packetTargetNodeId: targetId ?? state.packetTargetNodeId,
    );
  }

  void updateNodeIp(String nodeId, String ipAddress) {
    final updatedNodes = state.simulation.nodes
        .map((n) => n.id == nodeId ? n.copyWith(ipAddress: ipAddress.trim()) : n)
        .toList();
    state = state.copyWith(
      simulation: _copySim(nodes: updatedNodes),
      statusMessage: 'IP node diperbarui',
      detailMessage: '$nodeId → ${ipAddress.trim()}',
    );
  }

  void addNode(NodeType type) {
    if (state.simulation.id != 'sim-playground') return;
    final nextPc = state.pcCount + 1;
    final nextSwitch = state.switchCount + 1;
    final nextRouter = state.routerCount + 1;
    final nextServer = state.simulation.nodes.where((n) => n.type == NodeType.server).length + 1;

    String id;
    String label;
    String ip;
    int pcCount = state.pcCount;
    int switchCount = state.switchCount;
    int routerCount = state.routerCount;

    switch (type) {
      case NodeType.pc:
        id = 'pc-$nextPc';
        label = 'PC $nextPc';
        ip = '192.168.10.${nextPc + 10}';
        pcCount = nextPc;
        break;
      case NodeType.switchDevice:
        id = 'sw-$nextSwitch';
        label = 'Switch $nextSwitch';
        ip = '192.168.10.$nextSwitch';
        switchCount = nextSwitch;
        break;
      case NodeType.router:
        id = 'r-$nextRouter';
        label = 'Router $nextRouter';
        ip = '10.0.$nextRouter.1';
        routerCount = nextRouter;
        break;
      case NodeType.server:
        id = 'srv-$nextServer';
        label = 'Server $nextServer';
        ip = '192.168.10.${100 + nextServer}';
        break;
    }

    final offset = (state.simulation.nodes.length % 4) * 0.13;
    final node = NetworkNode(
      id: id,
      type: type,
      label: label,
      ipAddress: ip,
      x: (0.12 + offset).clamp(0.05, 0.8),
      y: (0.18 + ((state.simulation.nodes.length ~/ 4) * 0.16)).clamp(0.08, 0.72),
    );
    final nodes = [...state.simulation.nodes, node];
    state = state.copyWith(
      simulation: _copySim(nodes: nodes),
      packetSourceNodeId: state.packetSourceNodeId ?? node.id,
      packetTargetNodeId: state.packetTargetNodeId ?? node.id,
      pcCount: pcCount,
      switchCount: switchCount,
      routerCount: routerCount,
      statusMessage: '${node.label} ditambahkan',
    );
  }

  List<int>? _parseIpv4(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return null;
      nums.add(n);
    }
    return nums;
  }

  List<String> _findPath(String fromId, String toId) {
    final adjacency = <String, List<String>>{};
    for (final node in state.simulation.nodes) {
      adjacency[node.id] = [];
    }
    for (final c in state.simulation.connections) {
      adjacency[c.fromNodeId]?.add(c.toNodeId);
      adjacency[c.toNodeId]?.add(c.fromNodeId);
    }

    final queue = <String>[fromId];
    final parent = <String, String?>{fromId: null};
    int head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      if (cur == toId) break;
      for (final next in adjacency[cur] ?? const <String>[]) {
        if (parent.containsKey(next)) continue;
        parent[next] = cur;
        queue.add(next);
      }
    }
    if (!parent.containsKey(toId)) return [];

    final path = <String>[];
    String? cur = toId;
    while (cur != null) {
      path.add(cur);
      cur = parent[cur];
    }
    return path.reversed.toList();
  }

  bool _hasInvalidCable(List<String> path) {
    for (int i = 0; i < path.length - 1; i++) {
      final a = state.simulation.nodes.firstWhere((n) => n.id == path[i]);
      final b = state.simulation.nodes.firstWhere((n) => n.id == path[i + 1]);
      final cable = state.cableByLinkKey[_linkKey(a.id, b.id)] ?? CableType.straight;
      if (!_isCableCompatible(a.type, b.type, cable)) {
        return true;
      }
    }
    return false;
  }

  bool _isCableCompatible(NodeType a, NodeType b, CableType cable) {
    if (cable == CableType.wifi) {
      return (a == NodeType.pc || a == NodeType.router || a == NodeType.switchDevice) &&
          (b == NodeType.pc || b == NodeType.router || b == NodeType.switchDevice);
    }

    final sameType = a == b;
    if (sameType) {
      return cable == CableType.cross;
    }
    return cable == CableType.straight || cable == CableType.wifi;
  }

  String _linkKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  SimulationModel _copySim({
    List<NetworkNode>? nodes,
    List<NetworkConnection>? connections,
  }) {
    return SimulationModel(
      id: state.simulation.id,
      title: state.simulation.title,
      description: state.simulation.description,
      task: state.simulation.task,
      nodes: nodes ?? state.simulation.nodes,
      connections: connections ?? state.simulation.connections,
      scenarios: state.simulation.scenarios,
    );
  }

  String _pathLabel(List<String> path) {
    final sim = state.simulation;
    return path.map((id) {
      try {
        return sim.nodes.firstWhere((n) => n.id == id).label;
      } catch (_) {
        return id;
      }
    }).join(' → ');
  }
}

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, SimulationState>((ref) {
  return SimulationNotifier(ref.watch(simulationRepositoryProvider));
});
