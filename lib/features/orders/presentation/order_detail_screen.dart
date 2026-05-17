import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/order_models.dart';
import '../data/orders_repository.dart';

final _orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).getOrderDetail(id);
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load order', style: AppTextStyles.body)),
        data: (order) => _OrderDetailBody(order: order, ref: ref),
      ),
    );
  }
}

class _OrderDetailBody extends StatefulWidget {
  final Order order;
  final WidgetRef ref;
  const _OrderDetailBody({required this.order, required this.ref});
  @override
  State<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends State<_OrderDetailBody> {
  bool _cancelling = false;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    final status = s.toUpperCase();
    if (status.contains('CANCEL') || status.contains('FAILED')) return AppColors.danger;
    if (status == 'DELIVERED' || status == 'REFUNDED') return AppColors.secondary;
    if (status.contains('RETURN')) return AppColors.warning;
    return AppColors.primary;
  }

  bool get _canCancel {
    const cancellable = {'PAYMENT_PENDING', 'ORDER_RECEIVED', 'ORDER_TAKEN', 'ORDER_PROCESSING', 'DELIVERY_ASSIGNED'};
    return cancellable.contains(widget.order.orderStatus.toUpperCase());
  }

  Future<void> _cancel() async {
    final reason = _reasonCtrl.text.trim();
    setState(() => _cancelling = true);
    try {
      await widget.ref.read(ordersRepositoryProvider).cancelOrder(widget.order.id, reason.isEmpty ? 'Cancelled by customer' : reason);
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled and refund initiated.'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel order. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This will cancel your order and initiate a refund.'),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Order')),
          ElevatedButton(
            onPressed: _cancelling ? null : () { Navigator.pop(context); _cancel(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cancel & Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final ref = order.orderReference ?? order.id.substring(0, 8);
    final date = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
        : '';

    return RefreshIndicator(
      onRefresh: () => widget.ref.refresh(_orderDetailProvider(order.id).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#$ref', style: AppTextStyles.h3),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(order.orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(order.orderStatus.replaceAll('_', ' '),
                        style: AppTextStyles.label.copyWith(color: _statusColor(order.orderStatus))),
                  ),
                ]),
                if (date.isNotEmpty) Text(date, style: AppTextStyles.caption),
                if (order.deliveryAddress != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.deliveryAddress!, style: AppTextStyles.bodySmall)),
                  ]),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Items
          if (order.items.isNotEmpty) ...[
            Text('Items', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.medicineName, style: AppTextStyles.label),
                      if (item.brandName != null) Text('${item.brandName} — ${item.packLabel ?? ''}', style: AppTextStyles.caption),
                      Text('Qty: ${item.quantity}', style: AppTextStyles.bodySmall),
                    ])),
                    Text('₹${item.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.label),
                  ]),
                )).toList()),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Pricing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _PriceRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
                _PriceRow('Delivery', '₹${order.deliveryFee.toStringAsFixed(2)}'),
                const Divider(),
                _PriceRow('Total', '₹${order.finalAmount.toStringAsFixed(2)}', bold: true),
              ]),
            ),
          ),

          // Refund status
          if (order.payment?.refundStatus != null && order.payment!.refundStatus != 'NONE') ...[
            const SizedBox(height: 12),
            _RefundBanner(payment: order.payment!),
          ],

          // Cancel
          if (_canCancel) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _cancelling ? null : _showCancelDialog,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              child: _cancelling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                  : const Text('Cancel Order & Refund'),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PriceRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: bold ? AppTextStyles.label : AppTextStyles.body),
      const Spacer(),
      Text(value, style: bold ? AppTextStyles.label : AppTextStyles.body),
    ]),
  );
}

class _RefundBanner extends StatelessWidget {
  final OrderPayment payment;
  const _RefundBanner({required this.payment});

  @override
  Widget build(BuildContext context) {
    final status = payment.refundStatus?.toUpperCase() ?? '';
    final isCompleted = status == 'COMPLETED';
    final isFailed = status == 'FAILED';
    final amount = payment.refundAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.secondary.withOpacity(0.08)
            : isFailed ? AppColors.danger.withOpacity(0.08)
            : AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? AppColors.secondary.withOpacity(0.3)
            : isFailed ? AppColors.danger.withOpacity(0.3)
            : AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(
          isCompleted ? Icons.check_circle_outline : isFailed ? Icons.error_outline : Icons.hourglass_empty,
          color: isCompleted ? AppColors.secondary : isFailed ? AppColors.danger : AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isCompleted ? 'Refund Processed' : isFailed ? 'Refund Failed' : 'Refund In Progress',
            style: AppTextStyles.label,
          ),
          Text(
            isCompleted && amount != null
                ? '₹${amount.toStringAsFixed(2)} refunded to your original payment method'
                : isFailed
                    ? 'Please contact support'
                    : amount != null ? '₹${amount.toStringAsFixed(2)} — takes 5-7 business days' : '',
            style: AppTextStyles.bodySmall,
          ),
        ])),
      ]),
    );
  }
}
