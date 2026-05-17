import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pharmacy_models.dart';
import '../data/pharmacy_repository.dart';

final categoriesProvider = FutureProvider<List<MedicineCategory>>((ref) async {
  return ref.watch(pharmacyRepositoryProvider).getCategories();
});

class MedicineListState {
  final List<Medicine> items;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String search;
  final List<String> selectedCategories;
  final int offset;

  const MedicineListState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.search = '',
    this.selectedCategories = const [],
    this.offset = 0,
  });

  bool get hasMore => items.length < total;

  MedicineListState copyWith({
    List<Medicine>? items, int? total, bool? isLoading, bool? isLoadingMore,
    String? error, String? search, List<String>? selectedCategories, int? offset,
  }) => MedicineListState(
    items: items ?? this.items,
    total: total ?? this.total,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error,
    search: search ?? this.search,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    offset: offset ?? this.offset,
  );
}

class MedicineListNotifier extends StateNotifier<MedicineListState> {
  final PharmacyRepository _repo;
  MedicineListNotifier(this._repo) : super(const MedicineListState()) {
    load();
  }

  Future<void> load({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, offset: 0, items: [], total: 0);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final result = await _repo.getMedicines(
        search: state.search.isEmpty ? null : state.search,
        categoryIds: state.selectedCategories.isEmpty ? null : state.selectedCategories,
        limit: 20,
        offset: reset ? 0 : state.offset,
      );
      final newItems = reset ? result.items : [...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        total: result.total,
        isLoading: false,
        isLoadingMore: false,
        offset: newItems.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    load();
  }

  void toggleCategory(String id) {
    final cats = [...state.selectedCategories];
    cats.contains(id) ? cats.remove(id) : cats.add(id);
    state = state.copyWith(selectedCategories: cats);
    load();
  }

  void clearFilters() {
    state = state.copyWith(selectedCategories: [], search: '');
    load();
  }

  void loadMore() => load(reset: false);
}

final medicineListProvider = StateNotifierProvider<MedicineListNotifier, MedicineListState>((ref) {
  return MedicineListNotifier(ref.watch(pharmacyRepositoryProvider));
});
