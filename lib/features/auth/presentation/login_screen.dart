import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    try {
      await ref.read(authNotifierProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(e.toString());
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
      if (mounted) _showError(e.toString());
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Gradient background
          Container(
            height: mq.size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003D80), AppColors.primary, Color(0xFF0070E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
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
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'New Balan Medical',
                        style: TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w700,
                          fontSize: 24, color: Colors.white, letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Palakkad's trusted pharmacy & clinic",
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 28),

                // ── White card ───────────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 36, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gray300,
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
                              color: AppColors.gray100,
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

        ElevatedButton(
          onPressed: isLoading ? null : _login,
          child: isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Sign In'),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () {},
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
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscureRegPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
            ),
            helperText: 'Minimum 6 characters',
          ),
          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
        ),
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
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
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

        ElevatedButton(
          onPressed: isLoading ? null : _register,
          child: isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Create Account'),
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
              color: active ? Colors.white : AppColors.textSecondary,
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
