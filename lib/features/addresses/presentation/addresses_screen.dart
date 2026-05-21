import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../data/address_models.dart';
import '../data/address_repository.dart';

final _addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) async {
  return ref.watch(addressRepositoryProvider).getMyAddresses();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(_addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load addresses', style: AppTextStyles.body)),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_off_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No saved addresses', style: AppTextStyles.h3),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                itemBuilder: (_, i) => _AddressCard(
                  address: list[i],
                  onEdit: () => _showAddressForm(context, ref, address: list[i]),
                  onDelete: () async {
                    await ref.read(addressRepositoryProvider).deleteAddress(list[i].id);
                    ref.invalidate(_addressesProvider);
                  },
                  onSetDefault: () async {
                    await ref.read(addressRepositoryProvider).setDefault(list[i].id);
                    ref.invalidate(_addressesProvider);
                  },
                ),
              ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, WidgetRef ref, {Address? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        address: address,
        onSave: (data) async {
          if (address != null) {
            await ref.read(addressRepositoryProvider).updateAddress(address.id, data);
          } else {
            await ref.read(addressRepositoryProvider).createAddress(data);
          }
          ref.invalidate(_addressesProvider);
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  const _AddressCard({required this.address, required this.onEdit, required this.onDelete, required this.onSetDefault});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(address.label, style: AppTextStyles.label),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('Default', style: AppTextStyles.caption.copyWith(color: AppColors.secondary)),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(address.fullAddress, style: AppTextStyles.body),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(onPressed: onEdit, child: const Text('Edit')),
            if (!address.isDefault) TextButton(onPressed: onSetDefault, child: const Text('Set Default')),
            const Spacer(),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20)),
          ]),
        ]),
      ),
    );
  }
}

// Public so checkout screen can open "Add address" inline
class AddressFormSheet extends StatefulWidget {
  final Address? address;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const AddressFormSheet({super.key, this.address, required this.onSave});
  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

// Keep private alias so existing internal call-sites still compile
typedef _AddressFormSheet = AddressFormSheet;

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _label = TextEditingController();
  bool _isSaving = false;
  String? _error;

  // Fixed delivery area — not editable by user
  late final String _city;
  late final String _state;
  late final String _pincode;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    if (a != null) {
      _label.text = a.label;
      _street.text = a.street;
      _city    = a.city.isNotEmpty    ? a.city    : AppConfig.shopCity;
      _state   = a.state.isNotEmpty   ? a.state   : AppConfig.shopState;
      _pincode = a.pincode.isNotEmpty ? a.pincode : AppConfig.shopPincode;
    } else {
      _city    = AppConfig.shopCity;
      _state   = AppConfig.shopState;
      _pincode = AppConfig.shopPincode;
    }
  }

  @override
  void dispose() {
    _street.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _error = null; });
    try {
      await widget.onSave({
        'label': _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
        'street': _street.text.trim(),
        'city': _city,
        'state': _state,
        'pincode': _pincode,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _isSaving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Text(widget.address != null ? 'Edit Address' : 'Add Address', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger))),
                    ]),
                  ),
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Label', hintText: 'Home / Work / Other'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _street,
                  decoration: const InputDecoration(
                    labelText: 'Street Address *',
                    hintText: 'Door no, Street, Landmark…',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                // Fixed area — shown read-only
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Delivery Area (fixed)', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('$_city, $_state — $_pincode', style: AppTextStyles.body),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.address != null ? 'Update Address' : 'Save Address'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
