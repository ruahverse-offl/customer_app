import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/pharmacy_provider.dart';

class CategoryFilterModal extends ConsumerWidget {
  const CategoryFilterModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final selected = ref.watch(medicineListProvider).selectedCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text('Filter by Category', style: AppTextStyles.h3),
                  const Spacer(),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(medicineListProvider.notifier).clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cats.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load categories', style: AppTextStyles.body)),
                data: (categories) => ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final isSelected = selected.contains(cat.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => ref.read(medicineListProvider.notifier).toggleCategory(cat.id),
                      title: Text(cat.name, style: AppTextStyles.body),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(selected.isEmpty ? 'Show All' : 'Apply Filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
