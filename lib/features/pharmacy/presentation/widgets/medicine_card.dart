import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/pharmacy_models.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  const MedicineCard({super.key, required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = medicine.lowestPrice;
    final brandNames = medicine.purchasableOfferings
        .map((o) => o.brandName)
        .where((b) => b.isNotEmpty)
        .toSet()
        .take(2)
        .join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ───────────────────────────────────────────────
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image / placeholder
                  medicine.imageUrl != null
                      ? Image.network(medicine.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _Placeholder(rx: medicine.requiresPrescription))
                      : _Placeholder(rx: medicine.requiresPrescription),

                  // Bottom depth gradient
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x22000000)],
                        ),
                      ),
                    ),
                  ),

                  // Rx badge
                  if (medicine.requiresPrescription)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(
                            color: AppColors.danger.withOpacity(0.4),
                            blurRadius: 6, offset: const Offset(0, 2),
                          )],
                        ),
                        child: const Text('Rx',
                            style: TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800, fontFamily: 'Inter',
                            )),
                      ),
                    ),

                  // Brand count badge (if multiple brands available)
                  if (medicine.purchasableOfferings.length > 1)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${medicine.purchasableOfferings.length} brands',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.w600, fontFamily: 'Inter',
                            )),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info area ────────────────────────────────────────────────
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: AppTextStyles.label.copyWith(fontSize: 12.5, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (brandNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(brandNames,
                          style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: price != null
                              ? RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '₹${price.toStringAsFixed(0)}',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.primary, fontSize: 15,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '+',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text('—', style: AppTextStyles.caption),
                        ),
                        _CircleAddButton(onTap: onTap),
                      ],
                    ),
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

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool rx;
  const _Placeholder({required this.rx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = rx ? AppColors.danger : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rx
              ? isDark
                  ? [const Color(0xFF3B1219), const Color(0xFF4C1A20)]
                  : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)]
              : isDark
                  ? [const Color(0xFF0F2952), const Color(0xFF1A3A6B)]
                  : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                rx ? Icons.medication_liquid_rounded : Icons.medication_rounded,
                size: 28,
                color: color.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
