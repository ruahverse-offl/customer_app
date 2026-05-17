import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders', style: AppTextStyles.body)),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No orders yet', style: AppTextStyles.h3),
              ]))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(_ordersProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  Color _statusColor(String s) {
    final status = s.toUpperCase();
    if (status.contains('CANCEL') || status.contains('FAILED')) return AppColors.danger;
    if (status == 'DELIVERED' || status == 'REFUNDED') return AppColors.secondary;
    if (status.contains('RETURN')) return AppColors.warning;
    return AppColors.primary;
  }

  String _statusLabel(String s) => s.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final ref = order.orderReference ?? order.id.substring(0, 8);
    final date = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#$ref', style: AppTextStyles.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.orderStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusColor(order.orderStatus).withOpacity(0.3)),
                ),
                child: Text(_statusLabel(order.orderStatus),
                    style: AppTextStyles.caption.copyWith(color: _statusColor(order.orderStatus), fontWeight: FontWeight.w600)),
              ),
            ]),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(date, style: AppTextStyles.caption),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Text('₹${order.finalAmount.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ]),
          ]),
        ),
      ),
    );
  }
}
