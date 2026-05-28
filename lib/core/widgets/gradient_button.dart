import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium gradient CTA — mirrors `.btn-primary` from new_balan_fe.
///
/// Implementation notes:
///   • Explicit `height` (default 52) keeps the button sized correctly in any
///     parent slot (bottomNavigationBar, Column, sliver, etc.).
///   • No inner `Material` widget — InkWell uses the ambient Material from
///     the Scaffold above. Avoids spinning up an extra `_InkFeatures`
///     GlobalKey per button, which fixes a cold-start GlobalKey race.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Gradient gradient;
  final List<BoxShadow>? glow;
  final EdgeInsetsGeometry? padding;
  final double height;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.gradient = AppGradients.primary,
    this.glow,
    this.padding,
    this.height = 52,
  });

  const GradientButton.secondary({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.padding,
    this.height = 52,
  })  : gradient = AppGradients.secondary,
        glow = null;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final radius = BorderRadius.circular(AppRadius.md);

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: height,
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          boxShadow: disabled ? null : (glow ?? AppShadows.primaryGlow),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            splashColor: Colors.white.withOpacity(0.18),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
