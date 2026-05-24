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
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('${widget.medicine.name} added to cart')),
        ]),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (_selected?.mrp ?? 0) * _qty;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Medicine header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64, height: 64,
                      child: widget.medicine.imageUrl != null
                          ? Image.network(widget.medicine.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _SmallPlaceholder(rx: widget.medicine.requiresPrescription))
                          : _SmallPlaceholder(rx: widget.medicine.requiresPrescription),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.medicine.name,
                            style: AppTextStyles.h3.copyWith(fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (widget.medicine.requiresPrescription) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.danger),
                              const SizedBox(width: 4),
                              Text('Prescription required',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Brand list + qty
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                children: [
                  Text('Select Brand & Pack',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, letterSpacing: 0.3)),
                  const SizedBox(height: 10),
                  ...widget.medicine.purchasableOfferings.map((o) {
                    final isSelected = _selected?.id == o.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = o),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.brandName, style: AppTextStyles.label),
                                  if (o.manufacturer != null)
                                    Text(o.manufacturer!,
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                  if (o.packDescription != null)
                                    Text(o.packDescription!,
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${o.mrp.toStringAsFixed(2)}',
                                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                                const SizedBox(height: 4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20,
                                          key: ValueKey('check'))
                                      : const SizedBox(width: 20, key: ValueKey('empty')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Quantity selector
                  Row(
                    children: [
                      Text('Quantity', style: AppTextStyles.label),
                      const Spacer(),
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        enabled: _qty > 1,
                        onTap: () { if (_qty > 1) setState(() => _qty--); },
                      ),
                      SizedBox(
                        width: 44,
                        child: Text('$_qty',
                            style: AppTextStyles.labelLarge,
                            textAlign: TextAlign.center),
                      ),
                      _QtyButton(
                        icon: Icons.add_rounded,
                        enabled: true,
                        onTap: () => setState(() => _qty++),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Add to cart CTA
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (totalPrice > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$_qty × ₹${(_selected?.mrp ?? 0).toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                            Text('₹${totalPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _selected == null ? null : _addToCart,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.shopping_cart_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Add to Cart',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
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
  final bool enabled;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary.withOpacity(0.08) : AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: enabled ? AppColors.primary.withOpacity(0.2) : AppColors.border),
      ),
      child: Icon(icon, size: 18, color: enabled ? AppColors.primary : AppColors.textMuted),
    ),
  );
}

class _SmallPlaceholder extends StatelessWidget {
  final bool rx;
  const _SmallPlaceholder({required this.rx});

  @override
  Widget build(BuildContext context) => Container(
    color: (rx ? AppColors.danger : AppColors.primary).withOpacity(0.06),
    child: Center(
      child: Icon(
        rx ? Icons.medication_liquid_rounded : Icons.medication_rounded,
        size: 28,
        color: (rx ? AppColors.danger : AppColors.primary).withOpacity(0.4),
      ),
    ),
  );
}
