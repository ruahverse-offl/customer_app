import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/auth_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _nameCtrl.text = user?.fullName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _mobileCtrl.text = user?.mobileNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/users/${user.id}', data: {
        'full_name': _nameCtrl.text.trim(),
        'mobile_number': _mobileCtrl.text.trim(),
      });
      ref.read(authNotifierProvider.notifier).updateLocalUser(
        user.copyWith(fullName: _nameCtrl.text.trim(), mobileNumber: _mobileCtrl.text.trim()),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.secondary),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppColors.danger),
      );
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextFormField(controller: _emailCtrl, readOnly: true,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email cannot be changed')),
          const SizedBox(height: 12),
          TextFormField(controller: _mobileCtrl, keyboardType: TextInputType.phone, maxLength: 10,
              decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined), counterText: '')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
