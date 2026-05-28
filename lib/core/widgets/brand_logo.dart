import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Brand logo lockup — uses the official `new_balan_logo.png` asset.
/// Falls back to a pharmacy-themed monogram if the asset fails to load.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? tint;

  const BrandLogo({
    super.key,
    this.size = 56,
    this.showWordmark = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/new_balan_logo.png',
        fit: BoxFit.contain,
        color: tint,
        errorBuilder: (_, __, ___) => _MonogramFallback(size: size, tint: tint),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Balan',
              style: AppTextStyles.h3.copyWith(
                color: tint ?? AppColors.primary,
                fontSize: size * 0.34,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Medical & Clinic',
              style: AppTextStyles.caption.copyWith(
                color: tint?.withOpacity(0.75) ?? AppColors.textSecondary,
                fontSize: size * 0.18,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonogramFallback extends StatelessWidget {
  final double size;
  final Color? tint;
  const _MonogramFallback({required this.size, this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: AppShadows.primaryGlow,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_pharmacy_rounded,
        color: tint ?? Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
