import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/downloads.dart';
import '../../../core/utils/order_utils.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/price_row.dart';
import '../../../core/widgets/status_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/order_models.dart';
import '../data/orders_repository.dart';

pw.Font? _pdfRegularFont;
pw.Font? _pdfBoldFont;

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
        loading: () => const LoadingView(label: 'Loading order…'),
        error: (e, _) => ErrorStateView(
          title: 'Could not load order',
          message: 'Check your connection and try again.',
          onRetry: () => ref.refresh(_orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  final Order order;
  const _OrderDetailBody({required this.order});
  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _cancelling = false;
  bool _completingPayment = false;
  bool _loadingPaymentStatus = false;
  int? _secondsLeft;
  String? _pendingRazorpayOrderId;
  Timer? _countdownTimer;
  late Razorpay _razorpay;
  final _reasonCtrl = TextEditingController();

  bool get _isExpired => _secondsLeft != null && _secondsLeft! <= 0;

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

  bool get _canCancel {
    const cancellable = {'PAYMENT_PENDING', 'ORDER_RECEIVED', 'ORDER_TAKEN', 'ORDER_PROCESSING', 'DELIVERY_ASSIGNED'};
    return cancellable.contains(widget.order.orderStatus.toUpperCase());
  }

  bool get _canReorder => widget.order.orderStatus.toUpperCase() == 'DELIVERED';

  bool get _showInvoice {
    final s = widget.order.orderStatus.toUpperCase();
    return !s.contains('PENDING') && !s.contains('CANCELLED');
  }

  Future<void> _loadPaymentStatus() async {
    setState(() => _loadingPaymentStatus = true);
    try {
      final status = await ref.read(ordersRepositoryProvider).getPaymentStatus(widget.order.id);
      final seconds = int.tryParse(status['payment_expires_in_seconds']?.toString() ?? '0') ?? 0;
      final expired = status['payment_window_expired'] == true;
      if (mounted) {
        setState(() {
          _loadingPaymentStatus = false;
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
          _secondsLeft = 0;
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
      final data = await ref.read(ordersRepositoryProvider).retryPayment(widget.order.id);
      final user = ref.read(authNotifierProvider).user;
      _pendingRazorpayOrderId = data['razorpay_order_id']?.toString();
      _razorpay.open({
        'key': data['key_id'],
        'amount': data['amount'],
        'currency': 'INR',
        'name': 'New Balan Medical',
        'description': 'Order ${data['order_reference'] ?? widget.order.orderReference ?? ''}',
        'order_id': _pendingRazorpayOrderId,
        if (user != null) 'prefill': {'name': user.fullName, 'contact': user.mobileNumber ?? ''},
        'theme': {'color': '#0056B3'},
      });
    } catch (_) {
      if (mounted) {
        setState(() => _completingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resume payment. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) async {
    try {
      await ref.read(ordersRepositoryProvider).verifyRetryPayment({
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
        ref.invalidate(_orderDetailProvider(widget.order.id));
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
      await ref.read(ordersRepositoryProvider).reportCheckoutOutcome(
        widget.order.id, 'failed', errorDescription: res.message,
      );
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${res.message ?? "Unknown error"}'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      _pdfRegularFont ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
      _pdfBoldFont ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
      final regular = _pdfRegularFont!;
      final bold = _pdfBoldFont!;

      final order = widget.order;
      final refNum = order.orderReference ?? order.id.substring(0, 8);
      final date = order.createdAt != null ? formatOrderDate(order.createdAt!) : '';

      // Load app logo
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = (await rootBundle.load('assets/images/app_icon.png')).buffer.asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {}

      const primaryColor = PdfColor(0, 0.337, 0.702);   // #0056B3
      const lightGrey = PdfColor(0.96, 0.97, 0.98);
      const borderGrey = PdfColor(0.88, 0.91, 0.94);

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── Header: logo + shop details ──────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 64, height: 64,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  if (logoImage != null) pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NEW BALAN MEDICAL & CLINIC',
                            style: pw.TextStyle(font: bold, fontSize: 15, color: PdfColors.white)),
                        pw.SizedBox(height: 3),
                        pw.Text('120/a Poobalarayapuram 2nd Street',
                            style: pw.TextStyle(font: regular, fontSize: 9, color: const PdfColor(1, 1, 1, 0.7))),
                        pw.Text('Thoothukudi, Tamil Nadu 628001',
                            style: pw.TextStyle(font: regular, fontSize: 9, color: const PdfColor(1, 1, 1, 0.7))),
                        pw.SizedBox(height: 3),
                        pw.Text('+91 98948 80598  |  newbalanmedicals@gmail.com',
                            style: pw.TextStyle(font: regular, fontSize: 9, color: const PdfColor(1, 1, 1, 0.7))),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text('TAX INVOICE',
                            style: pw.TextStyle(font: bold, fontSize: 11, color: primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── Invoice metadata ─────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _pdfMetaRow('Invoice No.', '#$refNum', bold: bold, regular: regular),
                    pw.SizedBox(height: 4),
                    _pdfMetaRow('Date', date.isNotEmpty ? date : '—', bold: bold, regular: regular),
                  ])),
                  pw.Container(width: 1, height: 36, color: borderGrey),
                  pw.Expanded(child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      _pdfMetaRow('Payment', order.payment?.paymentStatus ?? orderStatusLabel(order.orderStatus),
                          bold: bold, regular: regular),
                      pw.SizedBox(height: 4),
                      _pdfMetaRow('Status', orderStatusLabel(order.orderStatus), bold: bold, regular: regular),
                    ]),
                  )),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Delivery address ─────────────────────────────────────────
            if (order.deliveryAddress != null)
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Deliver To', style: pw.TextStyle(font: bold, fontSize: 10, color: primaryColor)),
                pw.SizedBox(height: 4),
                pw.Text(order.deliveryAddress!,
                    style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
              ]),

            // ── Items table ──────────────────────────────────────────────
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(children: [
                // Table header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(5),
                      topRight: pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Row(children: [
                    pw.Expanded(flex: 5, child: pw.Text('Medicine', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white))),
                    pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text('Unit', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text('Amount', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                  ]),
                ),
                // Items
                ...order.items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return pw.Container(
                    color: i.isEven ? PdfColors.white : lightGrey,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 5, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(item.medicineName, style: pw.TextStyle(font: regular, fontSize: 10)),
                        if (item.brandName != null)
                          pw.Text(
                            '${item.brandName}${item.packLabel != null ? " · ${item.packLabel}" : ""}',
                            style: pw.TextStyle(font: regular, fontSize: 8.5, color: PdfColors.grey600),
                          ),
                      ])),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}',
                          style: pw.TextStyle(font: regular, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text('₹${item.unitPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: regular, fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 2, child: pw.Text('₹${item.totalPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ]),
                  );
                }),
              ]),
            ),

            pw.SizedBox(height: 10),

            // ── Totals ───────────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(children: [
                  _pdfTotalRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}', regular: regular),
                  pw.Divider(color: borderGrey, height: 1),
                  _pdfTotalRow('Delivery Fee', '₹${order.deliveryFee.toStringAsFixed(2)}', regular: regular),
                  if (order.subtotal - order.finalAmount + order.deliveryFee > 0) ...[
                    pw.Divider(color: borderGrey, height: 1),
                    _pdfTotalRow('Discount',
                      '− ₹${(order.subtotal + order.deliveryFee - order.finalAmount).toStringAsFixed(2)}',
                      regular: regular, valueColor: PdfColors.green700),
                  ],
                  pw.Divider(color: borderGrey, height: 1),
                  pw.Container(
                    color: primaryColor,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL', style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.white)),
                        pw.Text('₹${order.finalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.white)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            pw.Spacer(),

            // ── Footer ───────────────────────────────────────────────────
            pw.Divider(color: borderGrey),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Thank you for choosing New Balan Medical & Clinic!',
                    style: pw.TextStyle(font: bold, fontSize: 9, color: primaryColor)),
                pw.Text('newbalanmedicals@gmail.com',
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Text('This is a computer-generated invoice and does not require a signature.',
                style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ));

      final bytes = await pdf.save();
      final filename = 'invoice_$refNum.pdf';

      // Save to the device's public Downloads folder (Android: MediaStore;
      // iOS: app Documents). No storage permission required on Android 10+.
      final savedPath = await Downloads.saveBytes(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $savedPath'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => Printing.sharePdf(bytes: bytes, filename: filename),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save invoice. Try sharing instead.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  pw.Widget _pdfMetaRow(String label, String value, {required pw.Font bold, required pw.Font regular}) {
    return pw.Row(children: [
      pw.Text('$label: ', style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.grey700)),
      pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 9)),
    ]);
  }

  pw.Widget _pdfTotalRow(String label, String value, {required pw.Font regular, PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 10, color: valueColor)),
      ]),
    );
  }

  void _reorder() {
    final items = widget.order.items.where((i) => i.brandOfferingId != null).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reorderable items found.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    for (final item in items) {
      ref.read(cartProvider.notifier).addItem(CartItem(
        medicineId: item.brandOfferingId!,
        medicineName: item.medicineName,
        brandOfferingId: item.brandOfferingId!,
        packLabel: item.packLabel ?? '',
        price: item.unitPrice,
        mrp: item.unitPrice,
        quantity: item.quantity,
        requiresPrescription: false,
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} item(s) added to cart'),
        backgroundColor: AppColors.secondary,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => context.go('/checkout'),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final reason = _reasonCtrl.text.trim();
    setState(() => _cancelling = true);
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(
        widget.order.id, reason.isEmpty ? 'Cancelled by customer' : reason,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(
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
          TextButton(onPressed: () => context.pop(), child: const Text('Keep Order')),
          ElevatedButton(
            onPressed: _cancelling ? null : () { context.pop(); _cancel(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cancel & Refund'),
          ),
        ],
      ),
    );
  }

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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open prescription.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final refNum = order.orderReference ?? order.id.substring(0, 8);
    final date = order.createdAt != null ? formatOrderDate(order.createdAt!) : '';
    final isPending = order.orderStatus.toUpperCase() == 'PAYMENT_PENDING';

    return RefreshIndicator(
      onRefresh: () => ref.refresh(_orderDetailProvider(order.id).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isPending) ...[
            _PaymentPendingBanner(
              loadingStatus: _loadingPaymentStatus,
              expired: _isExpired,
              secondsLeft: _secondsLeft,
              completing: _completingPayment,
              onComplete: _completePayment,
              formatCountdown: _formatCountdown,
            ),
            const SizedBox(height: 12),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('#$refNum', style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: orderStatusColor(order.orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      orderStatusLabel(order.orderStatus),
                      style: AppTextStyles.label.copyWith(color: orderStatusColor(order.orderStatus)),
                    ),
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

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                PriceRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
                PriceRow('Delivery', '₹${order.deliveryFee.toStringAsFixed(2)}'),
                const Divider(),
                PriceRow('Total', '₹${order.finalAmount.toStringAsFixed(2)}', bold: true),
              ]),
            ),
          ),

          if (order.payment?.refundStatus != null && order.payment!.refundStatus != 'NONE') ...[
            const SizedBox(height: 12),
            _RefundBanner(payment: order.payment!),
          ],

          if (order.prescriptionPath != null && order.prescriptionPath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _viewPrescription,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View Prescription'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],

          if (_showInvoice) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloadInvoice,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Invoice'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],

          if (_canReorder) ...[
            const SizedBox(height: 12),
            GradientButton.secondary(
              onPressed: _reorder,
              label: 'Reorder',
              icon: Icons.shopping_cart_rounded,
            ),
          ],

          if (_canCancel) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _showCancelDialog,
              icon: _cancelling
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                    )
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Order & Refund'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
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

class _RefundBanner extends StatelessWidget {
  final OrderPayment payment;
  const _RefundBanner({required this.payment});

  Color _bannerColor(String status) {
    if (status == 'COMPLETED') return AppColors.secondary;
    if (status == 'FAILED') return AppColors.danger;
    return AppColors.warning;
  }

  IconData _bannerIcon(String status) {
    if (status == 'COMPLETED') return Icons.check_circle_outline;
    if (status == 'FAILED') return Icons.error_outline;
    return Icons.hourglass_empty;
  }

  String _bannerTitle(String status) {
    if (status == 'COMPLETED') return 'Refund Processed';
    if (status == 'FAILED') return 'Refund Failed';
    return 'Refund In Progress';
  }

  String _bannerBody(String status, double? amount) {
    if (status == 'COMPLETED' && amount != null) return '₹${amount.toStringAsFixed(2)} refunded to your original payment method';
    if (status == 'FAILED') return 'Please contact support';
    if (amount != null) return '₹${amount.toStringAsFixed(2)} — takes 5-7 business days';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final status = payment.refundStatus?.toUpperCase() ?? '';
    final color = _bannerColor(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(_bannerIcon(status), color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_bannerTitle(status), style: AppTextStyles.label),
          Text(_bannerBody(status, payment.refundAmount), style: AppTextStyles.bodySmall),
        ])),
      ]),
    );
  }
}
