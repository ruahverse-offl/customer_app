import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/pharmacy_models.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  const MedicineCard({super.key, required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lowestPrice = medicine.offerings.isEmpty ? 0.0
        : medicine.offerings.map((o) => o.price).reduce((a, b) => a < b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(medicine.name, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis)),
                        if (medicine.requiresPrescription)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                            ),
                            child: Text('Rx', style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    if (medicine.categoryName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(medicine.categoryName!, style: AppTextStyles.caption),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (lowestPrice > 0)
                          Text('from ₹${lowestPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                        const Spacer(),
                        Text('${medicine.offerings.length} option${medicine.offerings.length != 1 ? 's' : ''}',
                            style: AppTextStyles.caption),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
