import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/pharmacy_models.dart';
import '../providers/pharmacy_provider.dart';
import 'widgets/medicine_card.dart';
import 'widgets/brand_selection_modal.dart';
import 'widgets/category_filter_modal.dart';

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
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.push('/checkout')),
              if (cartCount > 0)
                Positioned(top: 6, right: 6, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search medicines…',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: state.selectedCategories.isNotEmpty,
                  label: Text('${state.selectedCategories.length}'),
                  child: IconButton(
                    icon: Icon(Icons.tune, color: hasFilters ? AppColors.primary : AppColors.textSecondary),
                    onPressed: _showCategoryFilter,
                    style: IconButton.styleFrom(
                      backgroundColor: hasFilters ? AppColors.primary.withOpacity(0.08) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error!, style: AppTextStyles.body.copyWith(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(medicineListProvider.notifier).load(),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                  child: const Text('Retry'),
                ),
              ],
            )))
          else if (state.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.medication_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No medicines found', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('Try a different search or category', style: AppTextStyles.bodySmall),
                ]),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                itemCount: state.items.length + (state.isLoadingMore ? 2 : 0),
                itemBuilder: (ctx, i) {
                  if (i >= state.items.length) {
                    return const Card(child: Center(child: CircularProgressIndicator()));
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
