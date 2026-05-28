import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_widgets.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';

/// Self-service account deletion — Google Play policy requirement.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmed) {
      _toast('Please confirm you understand this is permanent.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently remove your account, profile, and saved '
          'addresses. Order and invoice history is kept for legal compliance '
          'but is no longer linked to your personal details.\n\n'
          'You cannot undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount(
            password: _passCtrl.text,
            reason: _reasonCtrl.text,
          );
      if (!mounted) return;
      // Out of /account (which requires auth) before showing the toast.
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast(appErrorMessage(e));
      }
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                width: 80, height: 80,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.delete_forever_outlined,
                    color: AppColors.danger, size: 40),
              ),
              Text(
                'Permanently delete your account',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'This removes your profile and saved data from New Balan Medical.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              _InfoCard(
                icon: Icons.delete_outline_rounded,
                title: 'What gets deleted',
                bullets: const [
                  'Your name, email, and mobile number',
                  'Saved delivery addresses',
                  'Notification preferences',
                  'Cart contents',
                  'Login credentials (you will be signed out)',
                ],
                tint: AppColors.danger,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.gavel_rounded,
                title: 'What is retained (legal requirement)',
                bullets: const [
                  'Past orders and invoices (GST records)',
                  'Prescription scans we dispensed against',
                  'Anonymised transaction history',
                ],
                tint: AppColors.warning,
                footer: 'Retained data is anonymised so it can no longer be '
                    'linked to your personal details. See Privacy Policy §6.',
              ),
              const SizedBox(height: 24),

              Text('Confirm your password',
                  style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Your current password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 16),

              Text('Reason (optional)',
                  style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Help us improve — why are you leaving?',
                ),
              ),
              const SizedBox(height: 8),

              InkWell(
                onTap: () => setState(() => _confirmed = !_confirmed),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _confirmed,
                        onChanged: (v) => setState(() => _confirmed = v ?? false),
                        activeColor: AppColors.danger,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'I understand this action is permanent and cannot be undone.',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GradientButton(
                onPressed: _submitting ? null : _confirmAndDelete,
                label: 'Delete My Account',
                icon: Icons.delete_forever_rounded,
                loading: _submitting,
                gradient: const LinearGradient(
                  colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                glow: [
                  BoxShadow(
                    color: AppColors.danger.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => context.pop(),
                child: const Text('Keep My Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  final Color tint;
  final String? footer;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.bullets,
    required this.tint,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tint.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: tint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(b,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary, height: 1.5)),
                  ),
                ],
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                footer!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
