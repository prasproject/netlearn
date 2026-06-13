import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/material_model.dart';
import '../material_repository.dart';
import '../../seed/seed_data.dart';

/// Firebase Realtime Database implementation of MaterialRepository.
class RtdbMaterialRepository implements MaterialRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('materials');
  final _storage = GetStorage();

  List<MaterialModel> _mergeWithSeed(List<MaterialModel> remote) {
    final byId = <String, MaterialModel>{for (final m in remote) m.id: m};
    for (final seed in SeedData.materials) {
      byId.putIfAbsent(seed.id, () => seed);
    }
    final merged = byId.values.toList();
    merged.sort((a, b) {
      final o = a.order.compareTo(b.order);
      if (o != 0) return o;
      return a.unitNumber.compareTo(b.unitNumber);
    });
    return merged;
  }

  @override
  Future<MaterialModel?> getMaterialById(String id) async {
    final all = await getAllMaterials();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MaterialModel>> getAllMaterials() async {
    try {
      final snapshot = await _db.get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] = e.key;
          return MaterialModel.fromJson(map);
        }).toList();

        final merged = _mergeWithSeed(list);
        _storage.write('materials', merged.map((e) => e.toJson()).toList());
        return merged;
      }
    } catch (e) {
      // Fallback
    }

    // Offline / Cache
    final localData = _storage.read('materials');
    if (localData != null) {
      try {
        final cached = (localData as List)
            .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return _mergeWithSeed(cached);
      } catch (_) {}
    }

    return SeedData.materials;
  }
  
  @override
  Future<void> updateMaterial(MaterialModel material) async {
    await _db.child(material.id).set(material.toJson());
    // update cache
    final localData = _storage.read('materials');
    if (localData != null) {
      try {
        final list = (localData as List).map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final idx = list.indexWhere((m) => m.id == material.id);
        if (idx != -1) {
          list[idx] = material;
        } else {
          list.add(material);
        }
        _storage.write('materials', list.map((e) => e.toJson()).toList());
      } catch (_) {}
    }
  }

  @override
  Future<void> createMaterial(MaterialModel material) async {
    await updateMaterial(material);
  }

  @override
  Future<void> deleteMaterial(String id) async {
    await _db.child(id).remove();
    final localData = _storage.read('materials');
    if (localData == null) return;
    try {
      final list = (localData as List)
          .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
          .where((m) => m.id != id)
          .toList();
      _storage.write('materials', list.map((e) => e.toJson()).toList());
    } catch (_) {}
  }
}
