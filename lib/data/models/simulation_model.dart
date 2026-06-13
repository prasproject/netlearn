import 'dart:ui';

/// NetLearn — Simulation Model
/// Defines network topology with nodes, connections, and packet routing.
class SimulationModel {
  final String id;
  final String title;
  final String description;
  final String task;
  final List<NetworkNode> nodes;
  final List<NetworkConnection> connections;
  final List<SimulationScenario> scenarios;

  const SimulationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.task,
    required this.nodes,
    required this.connections,
    this.scenarios = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'task': task,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'connections': connections.map((c) => c.toJson()).toList(),
        'scenarios': scenarios.map((s) => s.toJson()).toList(),
      };

  factory SimulationModel.fromJson(Map<String, dynamic> json) =>
      SimulationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        task: json['task'] as String,
        nodes: (json['nodes'] as List)
            .map((n) => NetworkNode.fromJson(Map<String, dynamic>.from(n as Map)))
            .toList(),
        connections: (json['connections'] as List)
            .map((c) => NetworkConnection.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        scenarios: (json['scenarios'] as List?)
                ?.map(
                    (s) => SimulationScenario.fromJson(Map<String, dynamic>.from(s as Map)))
                .toList() ??
            [],
      );
}

/// A network device node in the simulation.
class NetworkNode {
  final String id;
  final NodeType type;
  final String label;
  final String ipAddress;
  final double x;
  final double y;

  const NetworkNode({
    required this.id,
    required this.type,
    required this.label,
    required this.ipAddress,
    required this.x,
    required this.y,
  });

  Offset get position => Offset(x, y);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'ipAddress': ipAddress,
        'x': x,
        'y': y,
      };

  factory NetworkNode.fromJson(Map<String, dynamic> json) => NetworkNode(
        id: json['id'] as String,
        type: NodeType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NodeType.pc,
        ),
        label: json['label'] as String,
        ipAddress: json['ipAddress'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  NetworkNode copyWith({
    String? label,
    String? ipAddress,
    double? x,
    double? y,
  }) => NetworkNode(
        id: id,
        type: type,
        label: label ?? this.label,
        ipAddress: ipAddress ?? this.ipAddress,
        x: x ?? this.x,
        y: y ?? this.y,
      );
}

/// Connection between two nodes.
class NetworkConnection {
  final String fromNodeId;
  final String toNodeId;
  final bool isActive;

  const NetworkConnection({
    required this.fromNodeId,
    required this.toNodeId,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
        'from': fromNodeId,
        'to': toNodeId,
        'isActive': isActive,
      };

  factory NetworkConnection.fromJson(Map<String, dynamic> json) =>
      NetworkConnection(
        fromNodeId: json['from'] as String,
        toNodeId: json['to'] as String,
        isActive: json['isActive'] as bool? ?? false,
      );

  NetworkConnection copyWith({bool? isActive}) => NetworkConnection(
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        isActive: isActive ?? this.isActive,
      );
}

/// A simulation scenario — a path from source to destination.
class SimulationScenario {
  final String fromNodeId;
  final String toNodeId;
  final List<String> correctPath;

  const SimulationScenario({
    required this.fromNodeId,
    required this.toNodeId,
    required this.correctPath,
  });

  Map<String, dynamic> toJson() => {
        'from': fromNodeId,
        'to': toNodeId,
        'correctPath': correctPath,
      };

  factory SimulationScenario.fromJson(Map<String, dynamic> json) =>
      SimulationScenario(
        fromNodeId: json['from'] as String,
        toNodeId: json['to'] as String,
        correctPath: (json['correctPath'] as List).cast<String>(),
      );
}

/// Network device types
enum NodeType {
  pc,
  router,
  switchDevice,
  server,
}
