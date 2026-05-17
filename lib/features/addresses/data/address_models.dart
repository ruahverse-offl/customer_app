class Address {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  String get fullAddress {
    final parts = [addressLine1, if (addressLine2 != null) addressLine2, city, state, pincode];
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'].toString(),
    label: j['label']?.toString() ?? 'Home',
    addressLine1: j['address_line_1']?.toString() ?? '',
    addressLine2: j['address_line_2']?.toString(),
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    pincode: j['pincode']?.toString() ?? '',
    isDefault: j['is_default'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'address_line_1': addressLine1,
    'address_line_2': addressLine2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'is_default': isDefault,
  };
}
