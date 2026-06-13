import '../../models/material_model.dart';
import '../../seed/seed_data.dart';
import '../material_repository.dart';

/// Mock material repository — uses SeedData.
class MockMaterialRepository implements MaterialRepository {
  final List<MaterialModel> _materials = List<MaterialModel>.from(SeedData.materials);

  @override
  Future<List<MaterialModel>> getAllMaterials() async => List<MaterialModel>.from(_materials);

  @override
  Future<MaterialModel?> getMaterialById(String id) async {
    try {
      return _materials.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateMaterial(MaterialModel material) async {
    final idx = _materials.indexWhere((m) => m.id == material.id);
    if (idx == -1) {
      _materials.add(material);
      return;
    }
    _materials[idx] = material;
  }

  @override
  Future<void> createMaterial(MaterialModel material) async {
    _materials.add(material);
  }

  @override
  Future<void> deleteMaterial(String id) async {
    _materials.removeWhere((m) => m.id == id);
  }
}
