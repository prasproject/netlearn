import 'package:flutter/material.dart';

import '../../domain/providers/simulation_provider.dart';

/// Things the student has done in this session that aren't part of the
/// simulation state itself (the state only knows the *current* topology).
class MissionStats {
  const MissionStats({
    this.devicesAdded = 0,
    this.linksCreated = 0,
    this.cablesUsed = const {},
    this.ipEdits = 0,
    this.sendAttempts = 0,
    this.successfulSends = 0,
    this.cameraMoved = false,
    this.nodesInspected = 0,
    this.routeChanges = 0,
  });

  final int devicesAdded;
  final int linksCreated;
  final Set<CableType> cablesUsed;
  final int ipEdits;
  final int sendAttempts;
  final int successfulSends;
  final bool cameraMoved;

  /// Devices tapped open to read their details.
  final int nodesInspected;

  /// Times the active route was switched.
  final int routeChanges;

  MissionStats copyWith({
    int? devicesAdded,
    int? linksCreated,
    Set<CableType>? cablesUsed,
    int? ipEdits,
    int? sendAttempts,
    int? successfulSends,
    bool? cameraMoved,
    int? nodesInspected,
    int? routeChanges,
  }) {
    return MissionStats(
      devicesAdded: devicesAdded ?? this.devicesAdded,
      linksCreated: linksCreated ?? this.linksCreated,
      cablesUsed: cablesUsed ?? this.cablesUsed,
      ipEdits: ipEdits ?? this.ipEdits,
      sendAttempts: sendAttempts ?? this.sendAttempts,
      successfulSends: successfulSends ?? this.successfulSends,
      cameraMoved: cameraMoved ?? this.cameraMoved,
      nodesInspected: nodesInspected ?? this.nodesInspected,
      routeChanges: routeChanges ?? this.routeChanges,
    );
  }
}

/// Where a step's action lives, so the guide can send the student straight to
/// the right set of controls instead of leaving them to hunt for it.
enum SimDockTab { build, send, layout, canvas }

/// One step of the guided walkthrough shown over the canvas.
class SimMission {
  const SimMission({
    required this.title,
    required this.hint,
    required this.icon,
    required this.isDone,
    required this.action,
    required this.tab,
  });

  final String title;
  final String hint;
  final IconData icon;

  /// Label of the button that takes the student to the control they need.
  final String action;

  /// Which control group that button opens.
  final SimDockTab tab;

  /// Completion is derived from what's on the canvas, so the checklist ticks
  /// itself as the student works instead of asking them to press "next".
  final bool Function(SimulationState state, MissionStats stats) isDone;
}

class SimulationMissions {
  SimulationMissions._();

  /// Free-build lab: the full loop of designing a network from nothing.
  static final List<SimMission> playground = [
    SimMission(
      title: 'Putar & perbesar kanvas',
      hint:
          'Geser kanvas untuk menggeser, cubit atau putar roda mouse untuk '
          'memperbesar, dan pakai tombol putar di sisi kanan kanvas.',
      icon: Icons.threesixty_rounded,
      action: 'Buka kontrol tampilan',
      tab: SimDockTab.layout,
      isDone: (state, stats) => stats.cameraMoved,
    ),
    SimMission(
      title: 'Tambahkan perangkat',
      hint:
          'Buka tab "Bangun" lalu tambahkan minimal dua perangkat, misalnya '
          'sebuah PC dan sebuah Switch.',
      icon: Icons.add_box_rounded,
      action: 'Buka tab Bangun',
      tab: SimDockTab.build,
      isDone: (state, stats) => stats.devicesAdded >= 2,
    ),
    SimMission(
      title: 'Hubungkan dengan kabel',
      hint:
          'Pilih jenis kabel di tab "Bangun", ketuk perangkat pertama, lalu '
          'ketuk perangkat kedua untuk memasang kabelnya.',
      icon: Icons.cable_rounded,
      action: 'Pilih jenis kabel',
      tab: SimDockTab.build,
      isDone: (state, stats) => stats.linksCreated >= 1,
    ),
    SimMission(
      title: 'Atur alamat IP',
      hint:
          'Ketuk sebuah perangkat, lalu ubah alamat IP-nya di panel yang '
          'muncul. Perangkat satu jaringan biasanya berbagi tiga angka awal.',
      icon: Icons.numbers_rounded,
      action: 'Ketuk perangkat di kanvas',
      tab: SimDockTab.canvas,
      isDone: (state, stats) => stats.ipEdits >= 1,
    ),
    SimMission(
      title: 'Kirim paket sampai berhasil',
      hint:
          'Di tab "Kirim", pilih pengirim dan tujuan lalu tekan Kirim Paket. '
          'Kalau gagal, baca pesan statusnya — di situ sebabnya.',
      icon: Icons.rocket_launch_rounded,
      action: 'Buka tab Kirim',
      tab: SimDockTab.send,
      isDone: (state, stats) => stats.successfulSends >= 1,
    ),
    SimMission(
      title: 'Coba jenis kabel lain',
      hint:
          'Pakai straight untuk perangkat berbeda jenis, cross untuk perangkat '
          'sejenis, dan wifi untuk koneksi nirkabel.',
      icon: Icons.settings_input_component_rounded,
      action: 'Buka tab Bangun',
      tab: SimDockTab.build,
      isDone: (state, stats) => stats.cablesUsed.length >= 2,
    ),
  ];

  /// Fixed topologies (bus, ring, tree, mesh, star): read, route, send.
  static final List<SimMission> topology = [
    SimMission(
      title: 'Amati bentuk topologinya',
      hint:
          'Lihat jaringan ini dari berbagai sudut: geser kanvas, atau pakai '
          'tombol putar / perbesar di sisi kanan kanvas.',
      icon: Icons.visibility_rounded,
      action: 'Buka kontrol tampilan',
      tab: SimDockTab.layout,
      isDone: (state, stats) => stats.cameraMoved,
    ),
    SimMission(
      title: 'Kenali perangkat & jalurnya',
      hint:
          'Ketuk salah satu perangkat di kanvas untuk melihat nama dan alamat '
          'IP-nya. Kabel yang menyala tebal adalah jalur yang akan dilewati '
          'paket — tombol "Rute" menggantinya bila ada jalur lain.',
      icon: Icons.alt_route_rounded,
      action: 'Ketuk perangkat di kanvas',
      tab: SimDockTab.canvas,
      // Reachable on every topology: some only have a single route, so this
      // must not depend on switching routes alone.
      isDone: (state, stats) => stats.nodesInspected >= 1 || stats.routeChanges >= 1,
    ),
    SimMission(
      title: 'Kirim paketnya',
      hint: 'Tekan Kirim Paket dan ikuti perjalanan paket dari hop ke hop.',
      icon: Icons.send_rounded,
      action: 'Buka tab Kirim',
      tab: SimDockTab.send,
      isDone: (state, stats) => stats.successfulSends >= 1,
    ),
    SimMission(
      title: 'Bandingkan dua rute',
      hint:
          'Ganti rute dengan tombol acak, kirim lagi, lalu bandingkan jumlah '
          'hop yang tampil di bilah status.',
      icon: Icons.compare_arrows_rounded,
      action: 'Buka tab Kirim',
      tab: SimDockTab.send,
      isDone: (state, stats) => stats.successfulSends >= 2,
    ),
  ];

  static List<SimMission> forSimulation(String id) =>
      id == 'sim-playground' ? playground : topology;
}
