import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium gradient CTA — mirrors `.btn-primary` from new_balan_fe.
/// Use sparingly: one primary CTA per screen.
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
    final effectiveGlow = glow ?? AppShadows.primaryGlow;

    // Explicit, finite height — keeps the button predictable in any slot
    // (bottomNavigationBar, Column, Row, etc.). Width follows fullWidth.
    final button = AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: height,
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: disabled ? null : effectiveGlow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            splashColor: Colors.white.withOpacity(0.15),
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

    return button;
  }
}
