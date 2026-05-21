import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../data/pharmacy_models.dart';

class BrandSelectionModal extends ConsumerStatefulWidget {
  final Medicine medicine;
  const BrandSelectionModal({super.key, required this.medicine});
  @override
  ConsumerState<BrandSelectionModal> createState() => _BrandSelectionModalState();
}

class _BrandSelectionModalState extends ConsumerState<BrandSelectionModal> {
  BrandOffering? _selected;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    final available = widget.medicine.purchasableOfferings;
    if (available.isNotEmpty) _selected = available.first;
  }

  void _addToCart() {
    if (_selected == null) return;
    ref.read(cartProvider.notifier).addItem(CartItem(
      medicineId: widget.medicine.id,
      medicineName: widget.medicine.name,
      brandOfferingId: _selected!.id,
      packLabel: _selected!.packLabel,
      price: _selected!.mrp,
      mrp: _selected!.mrp,
      quantity: _qty,
      requiresPrescription: widget.medicine.requiresPrescription,
      imageUrl: widget.medicine.imageUrl,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.medicine.name} added to cart'), backgroundColor: AppColors.secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Text(widget.medicine.name, style: AppTextStyles.h3)),
                  if (widget.medicine.requiresPrescription)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Rx required', style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('Select Brand & Pack', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...widget.medicine.purchasableOfferings.map((o) => GestureDetector(
                    onTap: () => setState(() => _selected = o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selected?.id == o.id ? AppColors.primary.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selected?.id == o.id ? AppColors.primary : AppColors.border,
                          width: _selected?.id == o.id ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.brandName, style: AppTextStyles.label),
                              if (o.manufacturer != null)
                                Text(o.manufacturer!, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                              if (o.packDescription != null)
                                Text(o.packDescription!, style: AppTextStyles.bodySmall),
                            ],
                          )),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${o.mrp.toStringAsFixed(2)}',
                                  style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                              if (_selected?.id == o.id)
                                const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                  // Qty
                  Row(
                    children: [
                      Text('Quantity', style: AppTextStyles.label),
                      const Spacer(),
                      _QtyButton(icon: Icons.remove, onTap: () { if (_qty > 1) setState(() => _qty--); }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_qty', style: AppTextStyles.labelLarge),
                      ),
                      _QtyButton(icon: Icons.add, onTap: () => setState(() => _qty++)),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _addToCart,
                  child: Text('Add to Cart — ₹${((_selected?.mrp ?? 0) * _qty).toStringAsFixed(2)}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: AppColors.textPrimary),
    ),
  );
}
