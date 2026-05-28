import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_views.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/pharmacy_models.dart';
import '../providers/pharmacy_provider.dart';
import 'widgets/medicine_card.dart';
import 'widgets/brand_selection_modal.dart';
import 'widgets/category_filter_modal.dart';

const _kAllId = '__all__';

class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});
  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(medicineListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(medicineListProvider.notifier).setSearch(q);
    });
  }

  void _showBrandModal(Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrandSelectionModal(medicine: medicine),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicineListProvider);
    final cartCount = ref.watch(cartProvider).totalItems;
    final hasFilters = state.selectedCategories.isNotEmpty || state.search.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/checkout'),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Text('$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Search medicines, brands…',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(medicineListProvider.notifier).setSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showCategoryFilter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: hasFilters ? Colors.white : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.tune_rounded,
                            color: hasFilters ? AppColors.primary : Colors.white, size: 22),
                        if (state.selectedCategories.isNotEmpty)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          _CategoryChips(
            selectedIds: state.selectedCategories,
            onToggle: (id) {
              if (id == _kAllId) {
                ref.read(medicineListProvider.notifier).clearFilters();
              } else {
                ref.read(medicineListProvider.notifier).toggleCategory(id);
              }
            },
          ),

          if (state.isLoading)
            const Expanded(child: _ShimmerGrid())
          else if (state.error != null)
            Expanded(child: ErrorStateView(
              title: 'Could not load medicines',
              message: state.error,
              onRetry: () => ref.read(medicineListProvider.notifier).load(),
            ))
          else if (state.items.isEmpty)
            Expanded(child: EmptyStateView(
              icon: Icons.medication_outlined,
              title: 'No medicines found',
              message: hasFilters
                  ? 'Try a different search or category.'
                  : 'Our catalog is empty right now. Check back soon.',
              actionLabel: hasFilters ? 'Clear filters' : null,
              onAction: hasFilters
                  ? () {
                      _searchCtrl.clear();
                      ref.read(medicineListProvider.notifier).clearFilters();
                    }
                  : null,
            ))
          else
            Expanded(
              child: GridView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                itemCount: state.items.length + (state.isLoadingMore ? 2 : 0),
                itemBuilder: (ctx, i) {
                  if (i >= state.items.length) {
                    return const _ShimmerMedicineCard();
                  }
                  return MedicineCard(
                    medicine: state.items[i],
                    onTap: () => _showBrandModal(state.items[i]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const _ShimmerMedicineCard(),
    );
  }
}

class _ShimmerMedicineCard extends StatelessWidget {
  const _ShimmerMedicineCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : AppColors.gray100;
    final highlightColor = isDark ? const Color(0xFF334155) : Colors.white;
    final blockColor = isDark ? const Color(0xFF334155) : AppColors.gray200;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area (55%)
            Expanded(
              flex: 55,
              child: Container(
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            // Info area (45%)
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 11, width: double.infinity,
                      decoration: BoxDecoration(
                        color: blockColor, borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 11, width: 70,
                      decoration: BoxDecoration(
                        color: blockColor, borderRadius: BorderRadius.circular(6)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 15, width: 44,
                          decoration: BoxDecoration(
                            color: blockColor, borderRadius: BorderRadius.circular(6)),
                        ),
                        const Spacer(),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(color: blockColor, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final List<String> selectedIds;
  final void Function(String id) onToggle;
  const _CategoryChips({required this.selectedIds, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.maybeWhen(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        final allSelected = selectedIds.isEmpty;
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: [
                _Chip(label: 'All', selected: allSelected, onTap: () => onToggle(_kAllId)),
                ...categories.map((c) {
                  final selected = selectedIds.contains(c.id);
                  return _Chip(label: c.name, selected: selected, onTap: () => onToggle(c.id));
                }),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBorder = isDark ? AppColorsDark.border : AppColors.border;
    final unselectedLabel = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : unselectedBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : unselectedLabel,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
