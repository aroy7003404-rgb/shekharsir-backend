import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/materials_repository.dart';
import 'auth_provider.dart';

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MaterialsRepository(apiService);
});

class MaterialsState {
  final bool isLoading;
  final List<dynamic> materials;
  final String searchQuery;
  final String selectedType;
  final String selectedBatch;
  final String? errorMessage;

  const MaterialsState({
    this.isLoading = false,
    this.materials = const [],
    this.searchQuery = '',
    this.selectedType = 'All',
    this.selectedBatch = 'All',
    this.errorMessage,
  });

  MaterialsState copyWith({
    bool? isLoading,
    List<dynamic>? materials,
    String? searchQuery,
    String? selectedType,
    String? selectedBatch,
    String? errorMessage,
  }) {
    return MaterialsState(
      isLoading: isLoading ?? this.isLoading,
      materials: materials ?? this.materials,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MaterialsNotifier extends StateNotifier<MaterialsState> {
  final MaterialsRepository _repository;

  MaterialsNotifier(this._repository) : super(const MaterialsState()) {
    loadMaterials();
  }

  Future<void> loadMaterials() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.searchMaterials(
        query: state.searchQuery,
        type: state.selectedType,
        batch: state.selectedBatch,
      );
      state = state.copyWith(isLoading: false, materials: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> fetchMaterials({String? targetBatch}) async {
    if (targetBatch != null) {
      state = state.copyWith(selectedBatch: targetBatch);
    }
    await loadMaterials();
  }

  Future<bool> uploadMaterial({
    required String title,
    required String description,
    required String targetBatch,
    required String fileType,
    String? fileUrl,
    String? filePath,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = List<dynamic>.from(state.materials)..insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'description': description,
        'target_batch': targetBatch,
        'file_type': fileType,
        'file_url': fileUrl ?? 'https://shekharsir-backend.onrender.com/static/materials/uploaded_notes.pdf',
        'upload_date': DateTime.now().toIso8601String(),
      });
      state = state.copyWith(isLoading: false, materials: list);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadMaterials();
  }

  void setSelectedType(String type) {
    state = state.copyWith(selectedType: type);
    loadMaterials();
  }

  void setSelectedBatch(String batch) {
    state = state.copyWith(selectedBatch: batch);
    loadMaterials();
  }
}

final materialsNotifierProvider =
    StateNotifierProvider.autoDispose<MaterialsNotifier, MaterialsState>((ref) {
  final repository = ref.watch(materialsRepositoryProvider);
  return MaterialsNotifier(repository);
});

final materialsProvider = materialsNotifierProvider;
