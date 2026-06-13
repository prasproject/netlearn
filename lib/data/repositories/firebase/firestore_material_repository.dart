import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/material_model.dart';
import '../material_repository.dart';

/// Firebase Firestore implementation of MaterialRepository.
class FirestoreMaterialRepository implements MaterialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MaterialModel>> getAllMaterials() async {
    final snapshot = await _firestore.collection('materials').orderBy('orderIndex').get();
    return snapshot.docs.map((doc) => MaterialModel.fromJson(doc.data())).toList();
  }

  @override
  Future<MaterialModel?> getMaterialById(String id) async {
    final doc = await _firestore.collection('materials').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return MaterialModel.fromJson(doc.data()!);
  }

  @override
  Future<void> updateMaterial(MaterialModel material) async {
    await _firestore
        .collection('materials')
        .doc(material.id)
        .set(material.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> createMaterial(MaterialModel material) async {
    await _firestore.collection('materials').doc(material.id).set(material.toJson());
  }

  @override
  Future<void> deleteMaterial(String id) async {
    await _firestore.collection('materials').doc(id).delete();
  }
}
