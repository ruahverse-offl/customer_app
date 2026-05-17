import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
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
  bool _completingPayment = false;
  bool _loadingPaymentStatus = false;
  bool _paymentWindowExpired = false;
  int? _secondsLeft;
  String? _pendingRazorpayOrderId;
  Timer? _countdownTimer;
  late Razorpay _razorpay;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    if (widget.order.orderStatus.toUpperCase() == 'PAYMENT_PENDING') {
      _loadPaymentStatus();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _countdownTimer?.cancel();
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

  bool get _canReorder => widget.order.orderStatus.toUpperCase() == 'DELIVERED';

  bool get _showInvoice {
    final s = widget.order.orderStatus.toUpperCase();
    return !s.contains('PENDING') && !s.contains('CANCELLED');
  }

  // ─── Payment countdown ───

  Future<void> _loadPaymentStatus() async {
    setState(() => _loadingPaymentStatus = true);
    try {
      final status = await widget.ref.read(ordersRepositoryProvider).getPaymentStatus(widget.order.id);
      final seconds = int.tryParse(status['payment_expires_in_seconds']?.toString() ?? '0') ?? 0;
      final expired = status['payment_window_expired'] == true;
      if (mounted) {
        setState(() {
          _loadingPaymentStatus = false;
          _paymentWindowExpired = expired;
          _secondsLeft = expired ? 0 : seconds;
        });
        if (!expired && seconds > 0) _startCountdown(seconds);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPaymentStatus = false);
    }
  }

  void _startCountdown(int seconds) {
    _secondsLeft = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft != null && _secondsLeft! > 0) {
          _secondsLeft = _secondsLeft! - 1;
        } else {
          _paymentWindowExpired = true;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _completePayment() async {
    setState(() => _completingPayment = true);
    try {
      final data = await widget.ref.read(ordersRepositoryProvider).retryPayment(widget.order.id);
      final user = widget.ref.read(authNotifierProvider).user;
      _pendingRazorpayOrderId = data['razorpay_order_id']?.toString();
      final options = {
        'key': data['key_id'],
        'amount': data['amount'],
        'currency': 'INR',
        'name': 'New Balan Medical',
        'description': 'Order ${data['order_reference'] ?? widget.order.orderReference ?? ''}',
        'order_id': _pendingRazorpayOrderId,
        if (user != null) 'prefill': {
          'name': user.fullName,
          'contact': user.mobileNumber ?? '',
        },
        'theme': {'color': '#0056B3'},
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _completingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resume payment. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) async {
    try {
      await widget.ref.read(ordersRepositoryProvider).verifyRetryPayment({
        'razorpay_order_id': _pendingRazorpayOrderId,
        'razorpay_payment_id': res.paymentId,
        'razorpay_signature': res.signature,
      });
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() { _completingPayment = false; _secondsLeft = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: AppColors.secondary),
        );
        widget.ref.invalidate(_orderDetailProvider(widget.order.id));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _completingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment received but verification failed. Contact support.'), backgroundColor: AppColors.warning),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse res) async {
    setState(() => _completingPayment = false);
    try {
      await widget.ref.read(ordersRepositoryProvider).reportCheckoutOutcome(
        widget.order.id, 'failed', errorDescription: res.message,
      );
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${res.message ?? "Unknown error"}'), backgroundColor: AppColors.danger),
      );
    }
  }

  // ─── Invoice ───

  Future<void> _downloadInvoice() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Inter-SemiBold.ttf');
      final regular = pw.Font.ttf(regularData);
      final bold = pw.Font.ttf(boldData);

      final order = widget.order;
      final refNum = order.orderReference ?? order.id.substring(0, 8);
      final date = order.createdAt != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
          : '';

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Column(children: [
              pw.Text('New Balan Medical', style: pw.TextStyle(font: bold, fontSize: 20)),
              pw.SizedBox(height: 2),
              pw.Text('${AppConfig.shopCity}, ${AppConfig.shopState} - ${AppConfig.shopPincode}',
                  style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text('Tax Invoice', style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.blueGrey800)),
            ])),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Order #$refNum', style: pw.TextStyle(font: bold, fontSize: 11)),
                if (date.isNotEmpty)
                  pw.Text(date, style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
              ]),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(order.orderStatus.replaceAll('_', ' '),
                    style: pw.TextStyle(font: regular, fontSize: 9)),
              ),
            ]),
            if (order.deliveryAddress != null) ...[
              pw.SizedBox(height: 8),
              pw.Text('Delivery Address:', style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(order.deliveryAddress!, style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
            ],
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(font: bold, fontSize: 10))),
              pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text('Amount', style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.right)),
            ]),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey300),
            ...order.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(children: [
                pw.Expanded(flex: 5, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(item.medicineName, style: pw.TextStyle(font: regular, fontSize: 10)),
                  if (item.brandName != null)
                    pw.Text('${item.brandName}${item.packLabel != null ? " - ${item.packLabel}" : ""}',
                        style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
                ])),
                pw.Expanded(flex: 1, child: pw.Text('${item.quantity}',
                    style: pw.TextStyle(font: regular, fontSize: 10), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 2, child: pw.Text('Rs.${item.totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regular, fontSize: 10), textAlign: pw.TextAlign.right)),
              ]),
            )),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            _pdfPriceRow('Subtotal', 'Rs.${order.subtotal.toStringAsFixed(2)}', regular: regular),
            _pdfPriceRow('Delivery Fee', 'Rs.${order.deliveryFee.toStringAsFixed(2)}', regular: regular),
            pw.SizedBox(height: 2),
            pw.Divider(color: PdfColors.grey400),
            _pdfPriceRow('Total', 'Rs.${order.finalAmount.toStringAsFixed(2)}', regular: bold, isBold: true),
            pw.Spacer(),
            pw.Center(child: pw.Text('Thank you for shopping with New Balan Medical!',
                style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey500))),
          ],
        ),
      ));

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoice_$refNum.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate invoice.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  pw.Widget _pdfPriceRow(String label, String value, {required pw.Font regular, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 10)),
        pw.Spacer(),
        pw.Text(value, style: pw.TextStyle(font: regular, fontSize: isBold ? 11 : 10)),
      ]),
    );
  }

  // ─── Reorder ───

  void _reorder() {
    final items = widget.order.items.where((i) => i.brandOfferingId != null).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reorderable items found.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    for (final item in items) {
      widget.ref.read(cartProvider.notifier).addItem(CartItem(
        medicineId: item.brandOfferingId!,
        medicineName: item.medicineName,
        brandOfferingId: item.brandOfferingId!,
        packLabel: item.packLabel ?? '',
        price: item.unitPrice,
        mrp: item.unitPrice,
        quantity: item.quantity,
        requiresPrescription: false,
        imageUrl: null,
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} item(s) added to cart'),
        backgroundColor: AppColors.secondary,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  // ─── Cancel ───

  Future<void> _cancel() async {
    final reason = _reasonCtrl.text.trim();
    setState(() => _cancelling = true);
    try {
      await widget.ref.read(ordersRepositoryProvider).cancelOrder(
        widget.order.id, reason.isEmpty ? 'Cancelled by customer' : reason,
      );
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

  // ─── Prescription ───

  String _buildPrescriptionUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/storage/$path';
    return '${AppConfig.apiOrigin}$cleanPath';
  }

  Future<void> _viewPrescription() async {
    final path = widget.order.prescriptionPath;
    if (path == null || path.isEmpty) return;
    final uri = Uri.tryParse(_buildPrescriptionUrl(path));
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open prescription.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final refNum = order.orderReference ?? order.id.substring(0, 8);
    final date = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
        : '';
    final isPending = order.orderStatus.toUpperCase() == 'PAYMENT_PENDING';

    return RefreshIndicator(
      onRefresh: () => widget.ref.refresh(_orderDetailProvider(order.id).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Payment pending banner
          if (isPending) ...[
            _PaymentPendingBanner(
              loadingStatus: _loadingPaymentStatus,
              expired: _paymentWindowExpired,
              secondsLeft: _secondsLeft,
              completing: _completingPayment,
              onComplete: _completePayment,
              formatCountdown: _formatCountdown,
            ),
            const SizedBox(height: 12),
          ],

          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#$refNum', style: AppTextStyles.h3),
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
                      if (item.brandName != null)
                        Text('${item.brandName} — ${item.packLabel ?? ''}', style: AppTextStyles.caption),
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

          // Prescription link
          if (order.prescriptionPath != null && order.prescriptionPath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _viewPrescription,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View Prescription'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],

          // Invoice download
          if (_showInvoice) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloadInvoice,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Invoice'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],

          // Reorder
          if (_canReorder) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _reorder,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('Reorder'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            ),
          ],

          // Cancel
          if (_canCancel) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cancelling ? null : _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: _cancelling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                  : const Text('Cancel Order & Refund'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PaymentPendingBanner extends StatelessWidget {
  final bool loadingStatus;
  final bool expired;
  final int? secondsLeft;
  final bool completing;
  final VoidCallback onComplete;
  final String Function(int) formatCountdown;

  const _PaymentPendingBanner({
    required this.loadingStatus,
    required this.expired,
    required this.secondsLeft,
    required this.completing,
    required this.onComplete,
    required this.formatCountdown,
  });

  @override
  Widget build(BuildContext context) {
    final color = expired ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(
            expired ? 'Payment window expired' : 'Payment pending',
            style: AppTextStyles.label.copyWith(color: color),
          )),
          if (loadingStatus)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else if (!expired && secondsLeft != null)
            Text(formatCountdown(secondsLeft!), style: AppTextStyles.h3.copyWith(color: color)),
        ]),
        if (!expired && !loadingStatus) ...[
          const SizedBox(height: 4),
          Text('Complete your payment before the window closes.',
              style: AppTextStyles.bodySmall.copyWith(color: color)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: completing ? null : onComplete,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: completing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Complete Payment', style: TextStyle(color: Colors.white)),
            ),
          ),
        ] else if (expired) ...[
          const SizedBox(height: 4),
          Text('This order has been cancelled due to payment timeout.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ]),
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
