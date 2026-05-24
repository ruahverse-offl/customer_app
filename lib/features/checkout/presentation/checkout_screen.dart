import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/price_row.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../addresses/data/address_models.dart';
import '../../addresses/data/address_repository.dart';
import '../../addresses/presentation/addresses_screen.dart';
import '../data/checkout_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<Address> _addresses = [];
  Address? _selectedAddress;
  String? _prescriptionPath;
  String? _couponCode;
  double _discount = 0;
  bool _isCouponValid = false;

  // Delivery settings loaded from API
  double _deliveryFeeRate = 40;
  double _freeDeliveryMin = 500;
  double? _freeDeliveryMax;

  bool _isSubmitting = false;
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingPaymentData;
  List<Map<String, dynamic>> _availableCoupons = [];

  double _calcDeliveryFee(double subtotal) {
    if (subtotal >= _freeDeliveryMin &&
        (_freeDeliveryMax == null || _freeDeliveryMax! <= 0 || subtotal <= _freeDeliveryMax!)) {
      return 0;
    }
    return _deliveryFeeRate;
  }

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
    _couponCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.mobileNumber ?? '';
    }
    List<Address> addrs = [];
    List<Map<String, dynamic>> coupons = [];
    await Future.wait([
      ref.read(addressRepositoryProvider).getMyAddresses().then((list) {
        addrs = list;
      }).catchError((_) {}),
      ref.read(checkoutRepositoryProvider).getDeliverySettings().then((s) {
        _deliveryFeeRate = double.tryParse(s['delivery_fee']?.toString() ?? '') ?? 40;
        _freeDeliveryMin = double.tryParse(
          (s['free_delivery_min_amount'] ?? s['free_delivery_threshold'])?.toString() ?? '') ?? 500;
        final rawMax = s['free_delivery_max_amount'];
        _freeDeliveryMax = rawMax != null ? double.tryParse(rawMax.toString()) : null;
      }).catchError((_) {}),
      ref.read(checkoutRepositoryProvider).getCoupons().then((c) {
        coupons = c;
      }).catchError((_) {}),
    ]);
    if (!mounted) return;
    setState(() {
      _addresses = addrs;
      if (addrs.isNotEmpty) {
        _selectedAddress = addrs.firstWhere((a) => a.isDefault, orElse: () => addrs.first);
      }
      _availableCoupons = coupons;
    });
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    try {
      final path = await ref.read(checkoutRepositoryProvider).uploadPrescription(file.path!, file.name);
      if (mounted) setState(() => _prescriptionPath = path);
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
      if (!mounted) return;
      if (res['valid'] == true) {
        setState(() {
          _couponCode = code;
          _isCouponValid = true;
          _discount = double.tryParse(res['discount_amount']?.toString() ?? '0') ?? 0;
        });
        _showSuccess(res['message']?.toString() ?? 'Coupon applied!');
      } else {
        setState(() { _isCouponValid = false; _discount = 0; _couponCode = null; });
        _showError(res['message']?.toString() ?? 'Invalid or expired coupon');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _isCouponValid = false; _discount = 0; _couponCode = null; });
      _showError('Invalid or expired coupon');
    }
  }

  void _removeCoupon() => setState(() {
    _couponCode = null;
    _isCouponValid = false;
    _discount = 0;
    _couponCtrl.clear();
  });

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;
    if (_selectedAddress == null) {
      _showError('Please select a delivery address');
      return;
    }
    if (cart.hasPrescriptionItems && _prescriptionPath == null) {
      _showError('Please upload a prescription for Rx items');
      return;
    }
    final user = ref.read(authNotifierProvider).user;
    if (user == null) { _showError('Please log in to continue'); return; }

    final subtotal = cart.subtotal;
    final deliveryFee = _calcDeliveryFee(subtotal);
    final finalAmount = subtotal + deliveryFee - _discount;

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'customer_name': _nameCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        'delivery_address': _selectedAddress!.fullAddress,
        'pincode': _selectedAddress!.pincode,
        'city': _selectedAddress!.city,
        'notes': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'coupon_code': _couponCode,
        'prescription_path': _prescriptionPath,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount_amount': _discount,
        'final_amount': finalAmount,
        'items': cart.items.map((i) => {
          'medicine_brand_id': i.brandOfferingId,
          'name': i.medicineName,
          'quantity': i.quantity,
          'price': i.price,
          'requires_prescription': i.requiresPrescription,
        }).toList(),
      };

      final initData = await ref.read(checkoutRepositoryProvider).initiatePayment(payload);
      _pendingPaymentData = initData;

      final options = {
        'key': initData['key_id'],
        'amount': initData['amount'],
        'currency': 'INR',
        'name': 'New Balan Medical',
        'description': 'Order ${initData['order_reference'] ?? ''}',
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

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.secondary),
  );

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressPickerSheet(
        addresses: _addresses,
        selected: _selectedAddress,
        onSelect: (addr) => setState(() => _selectedAddress = addr),
        onAddNew: _addNewAddress,
      ),
    );
  }

  Future<void> _addNewAddress() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(
        onSave: (data) async {
          await ref.read(addressRepositoryProvider).createAddress(data);
          // Refresh address list
          final updated = await ref.read(addressRepositoryProvider).getMyAddresses();
          if (mounted) {
            setState(() {
              _addresses = updated;
              // Auto-select newly added address (last one)
              if (updated.isNotEmpty) _selectedAddress = updated.last;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;
    final deliveryFee = _calcDeliveryFee(subtotal);
    final finalAmount = subtotal + deliveryFee - _discount;

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Add medicines from the pharmacy', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _placeOrder,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
            child: _isSubmitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Pay ₹${finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                  ]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact
            _Section(title: 'Contact Details', icon: Icons.person_outline_rounded, children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
            ]),

            // Delivery address selector
            _Section(title: 'Delivery Address', icon: Icons.location_on_outlined, children: [
              if (_selectedAddress != null) ...[
                _AddressTile(address: _selectedAddress!, onTap: _showAddressPicker),
              ] else ...[
                InkWell(
                  onTap: _showAddressPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Add or select a delivery address',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ]),
                  ),
                ),
              ],
            ]),

            // Prescription
            if (cart.hasPrescriptionItems)
              _Section(title: 'Prescription Required', icon: Icons.description_outlined, children: [
                if (_prescriptionPath != null)
                  Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text('Prescription uploaded', style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickPrescription,
                      child: const Text('Change'),
                    ),
                  ])
                else
                  OutlinedButton.icon(
                    onPressed: _pickPrescription,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Prescription (PDF/Image)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
              ]),

            // Coupon
            _Section(title: 'Coupon Code', icon: Icons.local_offer_outlined, children: [
              if (_isCouponValid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.local_offer_outlined, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_couponCode ?? '', style: AppTextStyles.label.copyWith(color: AppColors.secondary)),
                      Text('Saving ₹${_discount.toStringAsFixed(2)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.secondary)),
                    ])),
                    TextButton(onPressed: _removeCoupon, child: const Text('Remove',
                        style: TextStyle(color: AppColors.danger, fontSize: 12))),
                  ]),
                )
              else ...[
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _couponCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Enter coupon code'),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validateCoupon,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(80, 50)),
                    child: const Text('Apply'),
                  ),
                ]),
                if (_availableCoupons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Available:', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _availableCoupons.map((c) {
                      final code = c['code']?.toString() ?? '';
                      final disc = c['discount_percentage'] != null
                          ? ' — ${c['discount_percentage']}% off'
                          : '';
                      return ActionChip(
                        avatar: const Icon(Icons.local_offer_outlined, size: 14),
                        label: Text('$code$disc', style: AppTextStyles.caption),
                        onPressed: () {
                          _couponCtrl.text = code;
                          _validateCoupon();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ]),

            // Order note
            _Section(title: 'Order Note (optional)', icon: Icons.edit_note_rounded, children: [
              TextFormField(controller: _noteCtrl, maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Special instructions…',
                    hintText: 'Specific brand preferences, delivery instructions, etc.',
                  )),
            ]),

            // Order summary
            _Section(title: 'Order Summary', icon: Icons.receipt_long_outlined, children: [
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.medicineName, style: AppTextStyles.label, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text('${item.packLabel} × ${item.quantity}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  )),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: AppTextStyles.label),
                ]),
              )),
              const Divider(height: 20),
              PriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              if (deliveryFee == 0)
                PriceRow('Delivery Fee', 'FREE', valueColor: AppColors.secondary)
              else
                PriceRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
              if (_discount > 0)
                PriceRow('Coupon Discount', '−₹${_discount.toStringAsFixed(2)}', valueColor: AppColors.secondary),
              const Divider(height: 20),
              PriceRow('Total', '₹${finalAmount.toStringAsFixed(2)}', bold: true),
              if (deliveryFee == 0 && subtotal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'You saved ₹${_deliveryFeeRate.toStringAsFixed(0)} on delivery!',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                ),
            ]),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback onTap;
  const _AddressTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.location_on, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(address.label, style: AppTextStyles.label),
            if (address.isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Default', style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary, fontSize: 10)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(address.fullAddress, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 6),
        Text('Change', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
      ]),
    ),
  );
}

class _AddressPickerSheet extends StatelessWidget {
  final List<Address> addresses;
  final Address? selected;
  final ValueChanged<Address> onSelect;
  final VoidCallback onAddNew;
  const _AddressPickerSheet({required this.addresses, this.selected, required this.onSelect, required this.onAddNew});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    minChildSize: 0.4,
    maxChildSize: 0.85,
    builder: (_, ctrl) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('Select Address', style: AppTextStyles.h3),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              // Add new address button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onAddNew();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.add_location_alt_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Add New Address', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  ]),
                ),
              ),
              if (addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No saved addresses yet', style: AppTextStyles.body)),
                )
              else
                ...addresses.map((addr) {
                  final isSelected = selected?.id == addr.id;
                  return GestureDetector(
                    onTap: () {
                      onSelect(addr);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.location_on_outlined,
                            color: isSelected ? AppColors.primary : AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(addr.label, style: AppTextStyles.label),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 6),
                              Text('Default', style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary)),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(addr.fullAddress, style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                        ])),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        ),
      ]),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  const _Section({required this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: AppTextStyles.h3),
      ]),
      const SizedBox(height: 10),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      )),
      const SizedBox(height: 16),
    ],
  );
}
