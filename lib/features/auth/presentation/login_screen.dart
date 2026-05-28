import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_policy.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _tab = 0; // 0 = sign in, 1 = register
  bool _obscurePass = true;
  bool _obscureRegPass = true;
  bool _agreedToTerms = false;

  final _loginForm = GlobalKey<FormState>();
  final _registerForm = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    _nameCtrl.dispose(); _regEmailCtrl.dispose(); _regPassCtrl.dispose(); _mobileCtrl.dispose();
    super.dispose();
  }

  /// Unwraps a Dio failure into a short, user-readable string.
  /// Falls back to a generic message if the server didn't send one.
  String _friendlyError(Object e, {required bool isLogin}) {
    if (e is DioException) {
      // Network down / DNS failure / timeout — no response at all.
      if (e.response == null) {
        return "Can't reach the server. Check your internet and try again.";
      }
      // Auth endpoints map nicely: 401 → wrong creds, 409 → email taken.
      switch (e.response!.statusCode) {
        case 401:
          return 'Invalid email or password.';
        case 409:
          return 'An account with this email already exists.';
        case 422:
          return 'Please check your details and try again.';
        case 500:
        case 502:
        case 503:
          return 'Server hiccup. Please try again in a moment.';
      }
      // Fall back to the server's `detail` field if present.
      return apiErrorMessage(e);
    }
    return isLogin ? 'Could not sign in. Please try again.' : 'Could not create your account. Please try again.';
  }

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    try {
      await ref.read(authNotifierProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(_friendlyError(e, isLogin: true));
    }
  }

  Future<void> _register() async {
    if (!_registerForm.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please accept the Terms & Conditions to continue.');
      return;
    }
    try {
      await ref.read(authNotifierProvider.notifier).register(
        _nameCtrl.text.trim(),
        _regEmailCtrl.text.trim(),
        _regPassCtrl.text,
        _mobileCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(_friendlyError(e, isLogin: false));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showForgotPasswordHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 14),
              Text('Reset Your Password', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                "We'll reset your password manually. Reach out to our team and "
                "we'll verify your identity and set a temporary password.",
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _launch(AppConstants.storeWhatsApp);
                },
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('WhatsApp us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 10),
              GradientButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _launch('tel:${AppConstants.storePhone}');
                },
                label: 'Call ${AppConstants.storePhone}',
                icon: Icons.phone_rounded,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchTab(int t) {
    if (_tab == t) return;
    setState(() => _tab = t);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final mq = MediaQuery.of(context);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Gradient background — mirrors new_balan_fe page header
          Container(
            height: mq.size.height * 0.42,
            decoration: const BoxDecoration(gradient: AppGradients.primary),
            child: Stack(children: [
              Positioned(
                right: -60, top: -40,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                left: -40, top: 80,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ]),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(children: [
                      Container(
                        width: 84, height: 84,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const BrandLogo(size: 68),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Balan Medical',
                        style: TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w800,
                          fontSize: 26, color: Colors.white, letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${AppConfig.shopCity}'s trusted pharmacy & clinic since 1997",
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Form card ────────────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 36, height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tab switcher
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(children: [
                              _TabButton(label: 'Sign In', active: _tab == 0, onTap: () => _switchTab(0)),
                              _TabButton(label: 'Register', active: _tab == 1, onTap: () => _switchTab(1)),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Form content
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              child: _tab == 0
                                  ? _buildSignInForm(isLoading)
                                  : _buildRegisterForm(isLoading),
                            ),
                          ),
                        ),

                        // Footer links
                        _buildFooter(context),
                        SizedBox(height: mq.padding.bottom + 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(bool isLoading) {
    return Form(
      key: _loginForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back!', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text('Sign in to continue', style: AppTextStyles.bodySmall),
        const SizedBox(height: 24),

        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
        ),
        const SizedBox(height: 28),

        GradientButton(
          onPressed: isLoading ? null : _login,
          label: 'Sign In',
          icon: Icons.login_rounded,
          loading: isLoading,
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: _showForgotPasswordHelp,
            child: Text('Forgot Password?', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _registerForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Account', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text('Join New Balan Medical today', style: AppTextStyles.bodySmall),
        const SizedBox(height: 24),

        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: Icon(Icons.phone_outlined),
            prefixText: '+91  ',
            counterText: '',
          ),
          validator: (v) => (v == null || v.trim().length != 10) ? 'Enter a valid 10-digit number' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _regPassCtrl,
          obscureText: _obscureRegPass,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _register(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscureRegPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
            ),
            helperText: PasswordPolicy.requirementText,
            helperMaxLines: 3,
          ),
          validator: PasswordPolicy.validate,
        ),
        if (_regPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordStrengthMeter(password: _regPassCtrl.text),
        ],
        const SizedBox(height: 20),

        // Terms checkbox
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 22, height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy'),
                    ),
                    const TextSpan(text: ' of New Balan Medical.'),
                  ],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        GradientButton(
          onPressed: isLoading ? null : _register,
          label: 'Create Account',
          icon: Icons.person_add_alt_1_rounded,
          loading: isLoading,
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(label: 'Terms', onTap: () => context.push('/terms')),
            _dot(),
            _FooterLink(label: 'Privacy', onTap: () => context.push('/privacy')),
            _dot(),
            _FooterLink(label: 'Refund Policy', onTap: () => context.push('/refund-policy')),
          ],
        ),
      ]),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text('·', style: AppTextStyles.caption),
  );
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
  );
}
