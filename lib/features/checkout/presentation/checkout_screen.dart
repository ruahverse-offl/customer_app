import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../addresses/data/address_models.dart';
import '../../addresses/data/address_repository.dart';
import '../data/checkout_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  Address? _selectedAddress;
  String? _prescriptionUrl;
  String? _couponCode;
  double _discount = 0;
  double _deliveryFee = 40;
  bool _isSubmitting = false;
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingPaymentData;
  List<Map<String, dynamic>> _availableCoupons = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _loadDefaults();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _couponCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.mobileNumber ?? '';
    }
    try {
      final addresses = await ref.read(addressRepositoryProvider).getMyAddresses();
      final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      if (mounted) setState(() {
        _selectedAddress = def;
        _addressCtrl.text = def.fullAddress;
      });
    } catch (_) {}
    try {
      final settings = await ref.read(checkoutRepositoryProvider).getDeliverySettings();
      if (mounted) setState(() => _deliveryFee = double.tryParse(settings['delivery_fee']?.toString() ?? '40') ?? 40);
    } catch (_) {}
    try {
      final coupons = await ref.read(checkoutRepositoryProvider).getCoupons();
      if (mounted) setState(() => _availableCoupons = coupons);
    } catch (_) {}
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    try {
      final url = await ref.read(checkoutRepositoryProvider).uploadPrescription(file.path!, file.name);
      if (mounted) setState(() => _prescriptionUrl = url);
    } catch (e) {
      _showError('Failed to upload prescription');
    }
  }

  Future<void> _validateCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    final subtotal = ref.read(cartProvider).subtotal;
    try {
      final res = await ref.read(checkoutRepositoryProvider).validateCoupon(code, subtotal);
      setState(() {
        _couponCode = code;
        _discount = double.tryParse(res['discount_amount']?.toString() ?? '0') ?? 0;
      });
    } catch (_) {
      _showError('Invalid or expired coupon');
    }
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;
    if (cart.hasPrescriptionItems && _prescriptionUrl == null) {
      _showError('Please upload a prescription for Rx items');
      return;
    }

    final user = ref.read(authNotifierProvider).user;
    final subtotal = cart.subtotal;
    final finalAmount = subtotal + _deliveryFee - _discount;

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'customer_id': user?.id,
        'customer_name': _nameCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        'delivery_address': _addressCtrl.text.trim(),
        'order_note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'coupon_code': _couponCode,
        'prescription_url': _prescriptionUrl,
        'subtotal': subtotal,
        'delivery_fee': _deliveryFee,
        'discount_amount': _discount,
        'final_amount': finalAmount,
        'items': cart.items.map((i) => {
          'brand_offering_id': i.brandOfferingId,
          'quantity': i.quantity,
          'unit_price': i.price,
        }).toList(),
      };

      final initData = await ref.read(checkoutRepositoryProvider).initiatePayment(payload);
      _pendingPaymentData = initData;

      final options = {
        'key': initData['key_id'],
        'amount': initData['amount'],
        'currency': 'INR',
        'name': 'New Balan Medical',
        'description': 'Order ${initData['order_reference']}',
        'order_id': initData['razorpay_order_id'],
        'prefill': {'name': _nameCtrl.text, 'contact': _phoneCtrl.text},
        'theme': {'color': '#0056B3'},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Could not initiate payment. Please try again.');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) async {
    try {
      await ref.read(checkoutRepositoryProvider).verifyPayment({
        'razorpay_order_id': _pendingPaymentData?['razorpay_order_id'],
        'razorpay_payment_id': res.paymentId,
        'razorpay_signature': res.signature,
        'order_id': _pendingPaymentData?['order_id'],
      });
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess('Order placed successfully!');
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
      _showError('Payment received but verification failed. Contact support.');
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    setState(() => _isSubmitting = false);
    _showError('Payment failed: ${res.message}');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;
    final finalAmount = subtotal + _deliveryFee - _discount;

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Add medicines from the pharmacy', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact
            _Section(title: 'Contact Details', children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
            ]),

            // Delivery address
            _Section(title: 'Delivery Address', children: [
              TextFormField(controller: _addressCtrl, maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Delivery Address')),
            ]),

            // Prescription
            if (cart.hasPrescriptionItems)
              _Section(title: 'Prescription Required', children: [
                if (_prescriptionUrl != null)
                  Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text('Prescription uploaded', style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
                  ])
                else
                  OutlinedButton.icon(
                    onPressed: _pickPrescription,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Prescription (PDF/Image)'),
                  ),
              ]),

            // Coupon
            _Section(title: 'Coupon Code', children: [
              Row(children: [
                Expanded(child: TextFormField(controller: _couponCtrl,
                    decoration: const InputDecoration(labelText: 'Enter coupon code'))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _validateCoupon,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(80, 50)),
                    child: const Text('Apply')),
              ]),
              if (_availableCoupons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Available coupons:', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _availableCoupons.map((c) {
                    final code = c['code']?.toString() ?? '';
                    final disc = c['discount_value'] != null
                        ? ' — ${c['discount_type'] == 'PERCENTAGE' ? '${c['discount_value']}%' : '₹${c['discount_value']}'} off'
                        : '';
                    return ActionChip(
                      label: Text('$code$disc', style: AppTextStyles.caption),
                      onPressed: () {
                        _couponCtrl.text = code;
                        _validateCoupon();
                      },
                    );
                  }).toList(),
                ),
              ],
              if (_discount > 0) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Coupon applied! Saving ₹${_discount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary)),
              ),
            ]),

            // Order note
            _Section(title: 'Order Note (optional)', children: [
              TextFormField(controller: _noteCtrl, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Special instructions…')),
            ]),

            // Order summary
            _Section(title: 'Order Summary', children: [
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.medicineName, style: AppTextStyles.label),
                      Text('${item.packLabel} × ${item.quantity}', style: AppTextStyles.caption),
                    ],
                  )),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: AppTextStyles.label),
                ]),
              )),
              const Divider(),
              _PriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              _PriceRow('Delivery Fee', '₹${_deliveryFee.toStringAsFixed(2)}'),
              if (_discount > 0) _PriceRow('Discount', '−₹${_discount.toStringAsFixed(2)}', color: AppColors.secondary),
              const Divider(),
              _PriceRow('Total', '₹${finalAmount.toStringAsFixed(2)}', bold: true),
            ]),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _placeOrder,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Pay ₹${finalAmount.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.h3),
      const SizedBox(height: 12),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      )),
      const SizedBox(height: 16),
    ],
  );
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _PriceRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: bold ? AppTextStyles.label : AppTextStyles.body),
      const Spacer(),
      Text(value, style: (bold ? AppTextStyles.label : AppTextStyles.body)
          .copyWith(color: color ?? (bold ? AppColors.textPrimary : null))),
    ]),
  );
}
