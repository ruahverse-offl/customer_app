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
        .join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — aspect ratio > 1 keeps image shorter so text fits below
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: medicine.imageUrl != null
                    ? Image.network(
                        medicine.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderImage(rx: medicine.requiresPrescription),
                      )
                    : _PlaceholderImage(rx: medicine.requiresPrescription),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: AppTextStyles.label.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (medicine.requiresPrescription)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Rx',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10)),
                        ),
                    ]),

                    if (brandNames.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        brandNames,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    Row(children: [
                      if (price != null)
                        Flexible(
                          child: Text(
                            '₹${price.toStringAsFixed(0)}+',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.primary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Text('—', style: AppTextStyles.caption),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
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

class _PlaceholderImage extends StatelessWidget {
  final bool rx;
  const _PlaceholderImage({required this.rx});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primary.withOpacity(0.05),
        child: Center(
          child: Icon(
            rx ? Icons.medication_liquid_outlined : Icons.medication_outlined,
            size: 40,
            color: AppColors.primary.withOpacity(0.25),
          ),
        ),
      );
}
