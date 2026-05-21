import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/order_utils.dart';
import '../data/order_models.dart';
import '../data/orders_repository.dart';

final _ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final result = await ref.watch(ordersRepositoryProvider).getOrders();
  return result.items;
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Failed to load orders', style: AppTextStyles.body),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.refresh(_ordersProvider.future),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (list) => list.isEmpty
            ? _EmptyOrders(onShop: () => context.go('/pharmacy'))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(_ordersProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _OrderCard(
                    order: list[i],
                    onTap: () => context.push('/profile/orders/${list[i].id}'),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyOrders({required this.onShop});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('No Orders Yet', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text('Your order history will appear here once you place your first order.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onShop,
          icon: const Icon(Icons.medication, size: 18),
          label: const Text('Browse Pharmacy'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
        ),
      ]),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ref = order.orderReference ?? '#${order.id.substring(0, 8).toUpperCase()}';
    final date = order.createdAt != null ? formatOrderDate(order.createdAt!) : '';
    final statusColor = orderStatusColor(order.orderStatus);
    final statusLabel = order.orderStatus.replaceAll('_', ' ');
    final itemCount = order.itemCount;
    final firstItem = order.items.isNotEmpty ? order.items.first.medicineName : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(statusLabel.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Flexible(fit: FlexFit.loose, child: Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(ref, style: AppTextStyles.labelLarge, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text('₹${order.finalAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ]),
                const SizedBox(height: 4),
                if (firstItem.isNotEmpty)
                  Text(
                    itemCount > 1 ? '$firstItem +${itemCount - 1} more' : firstItem,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  _InfoChip(icon: Icons.inventory_2_outlined, label: '$itemCount item${itemCount == 1 ? '' : 's'}'),
                  if (order.deliveryFee > 0) ...[
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.local_shipping_outlined, label: '₹${order.deliveryFee.toStringAsFixed(0)} delivery'),
                  ],
                ]),
              ])),
            ]),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(children: [
              Text('View Order Details', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 13, color: AppColors.primary),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
  ]);
}
