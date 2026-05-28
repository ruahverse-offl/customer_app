import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mirrors `app/utils/password_policy.py` on the backend.
/// Keep both in sync — if the server tightens its rules, update here too.
class PasswordPolicy {
  static const requirementText =
      'At least 8 characters, with an uppercase letter, a lowercase letter, and a special character.';

  static final _upper = RegExp(r'[A-Z]');
  static final _lower = RegExp(r'[a-z]');
  static final _special = RegExp(r'[^A-Za-z0-9]');

  /// Returns null if valid, or a short error message if invalid.
  /// Designed to plug into a `validator` on `TextFormField`.
  static String? validate(String? raw) {
    final p = (raw ?? '').trim();
    if (p.isEmpty) return 'Required';
    if (p.length < 8) return 'Must be at least 8 characters';
    if (!_upper.hasMatch(p)) return 'Must include an uppercase letter';
    if (!_lower.hasMatch(p)) return 'Must include a lowercase letter';
    if (!_special.hasMatch(p)) return 'Must include a special character';
    return null;
  }

  static int strength(String raw) {
    final p = raw.trim();
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (_upper.hasMatch(p)) score++;
    if (_lower.hasMatch(p)) score++;
    if (_special.hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    return score; // 0–6
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final s = PasswordPolicy.strength(password);
    final pct = (s / 6).clamp(0.0, 1.0);
    final (color, label) = switch (s) {
      <= 2 => (AppColors.danger, 'Weak'),
      <= 4 => (AppColors.warning, 'Okay'),
      _ => (AppColors.secondary, 'Strong'),
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
