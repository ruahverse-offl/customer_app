import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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

class _AddressFormSheet extends StatefulWidget {
  final Address? address;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddressFormSheet({this.address, required this.onSave});
  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _label = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    if (a != null) {
      _label.text = a.label;
      _line1.text = a.addressLine1;
      _line2.text = a.addressLine2 ?? '';
      _city.text = a.city;
      _state.text = a.state;
      _pincode.text = a.pincode;
    }
  }

  @override
  void dispose() {
    _line1.dispose(); _line2.dispose(); _city.dispose();
    _state.dispose(); _pincode.dispose(); _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave({
        'label': _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
        'address_line_1': _line1.text.trim(),
        'address_line_2': _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.address != null ? 'Edit Address' : 'Add Address', style: AppTextStyles.h3),
              const SizedBox(height: 20),
              TextFormField(controller: _label, decoration: const InputDecoration(labelText: 'Label (Home / Work / Other)')),
              const SizedBox(height: 12),
              TextFormField(controller: _line1, decoration: const InputDecoration(labelText: 'Address Line 1')),
              const SizedBox(height: 12),
              TextFormField(controller: _line2, decoration: const InputDecoration(labelText: 'Address Line 2 (optional)')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _state, decoration: const InputDecoration(labelText: 'State'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _pincode, keyboardType: TextInputType.number, maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Pincode', counterText: '')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.address != null ? 'Update Address' : 'Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
