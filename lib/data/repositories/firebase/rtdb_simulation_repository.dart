import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import '../../models/simulation_model.dart';
import '../simulation_repository.dart';
import '../../seed/seed_data.dart';

/// Firebase Realtime Database implementation of SimulationRepository.
class RtdbSimulationRepository implements SimulationRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('simulations');

  @override
  Future<SimulationModel> getSimulation(String id) async {
    try {
      final snapshot = await _db.child(id).get();
      if (snapshot.exists) {
        Map<String, dynamic> map;
        try {
          map = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          map = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        map['id'] = id;
        return SimulationModel.fromJson(map);
      }
    } catch (e) {
      // Fallback
    }
    return SeedData.simulations.firstWhere((s) => s.id == id, orElse: () => SeedData.defaultSimulation);
  }

  @override
  Future<List<SimulationModel>> getAllSimulations() async {
    try {
      final snapshot = await _db.get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        return data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] = e.key;
          return SimulationModel.fromJson(map);
        }).toList();
      }
    } catch (e) {
      // Fallback
    }
    return SeedData.simulations;
  }
}
