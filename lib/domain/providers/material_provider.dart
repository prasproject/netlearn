import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/material_repository.dart';
import 'repository_providers.dart';

/// Material browsing state
class MaterialState {
  final List<MaterialModel> materials;
  final int currentSlideIndex;
  final String? activeUnitId;
  final Set<String> bookmarkedSlides; // "unitId:slideIndex"

  const MaterialState({
    this.materials = const [],
    this.currentSlideIndex = 0,
    this.activeUnitId,
    this.bookmarkedSlides = const {},
  });

  MaterialState copyWith({
    List<MaterialModel>? materials,
    int? currentSlideIndex,
    String? activeUnitId,
    Set<String>? bookmarkedSlides,
  }) {
    return MaterialState(
      materials: materials ?? this.materials,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      activeUnitId: activeUnitId ?? this.activeUnitId,
      bookmarkedSlides: bookmarkedSlides ?? this.bookmarkedSlides,
    );
  }
}

class MaterialNotifier extends StateNotifier<MaterialState> {
  final MaterialRepository _repo;

  MaterialNotifier(this._repo) : super(const MaterialState()) {
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final materials = await _repo.getAllMaterials();
    state = state.copyWith(materials: materials);
  }

  Future<void> refreshMaterials() async => _loadMaterials();

  void setActiveUnit(String unitId) {
    state = state.copyWith(activeUnitId: unitId, currentSlideIndex: 0);
  }

  void resetLearningSession() {
    state = MaterialState(materials: state.materials);
  }

  void nextSlide() {
    final unit = state.materials.firstWhere((m) => m.id == state.activeUnitId,
        orElse: () => state.materials.first);
    if (state.currentSlideIndex < unit.totalSlides - 1) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex + 1);
    }
  }

  void previousSlide() {
    if (state.currentSlideIndex > 0) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex - 1);
    }
  }

  void goToSlide(int index) {
    state = state.copyWith(currentSlideIndex: index);
  }

  void toggleBookmark(String unitId, int slideIndex) {
    final key = '$unitId:$slideIndex';
    final bookmarks = Set<String>.from(state.bookmarkedSlides);
    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
    } else {
      bookmarks.add(key);
    }
    state = state.copyWith(bookmarkedSlides: bookmarks);
  }

  bool isBookmarked(String unitId, int slideIndex) {
    return state.bookmarkedSlides.contains('$unitId:$slideIndex');
  }

  Future<void> createMaterial(MaterialModel material) async {
    await _repo.createMaterial(material);
    await _loadMaterials();
  }

  Future<void> updateMaterial(MaterialModel material) async {
    await _repo.updateMaterial(material);
    await _loadMaterials();
  }

  Future<void> deleteMaterial(String id) async {
    await _repo.deleteMaterial(id);
    await _loadMaterials();
  }
}

final materialProvider =
    StateNotifierProvider<MaterialNotifier, MaterialState>((ref) {
  return MaterialNotifier(ref.watch(materialRepositoryProvider));
});
