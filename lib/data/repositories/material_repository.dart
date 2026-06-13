import '../models/material_model.dart';

/// Abstract material repository.
abstract class MaterialRepository {
  Future<List<MaterialModel>> getAllMaterials();
  Future<MaterialModel?> getMaterialById(String id);
  Future<void> createMaterial(MaterialModel material);
  Future<void> updateMaterial(MaterialModel material);
  Future<void> deleteMaterial(String id);
}
