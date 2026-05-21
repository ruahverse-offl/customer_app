class Address {
  final String id;
  final String label;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? country;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.country,
    required this.isDefault,
  });

  String get fullAddress {
    final parts = [street, city, state, pincode];
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'].toString(),
    label: j['label']?.toString() ?? 'Home',
    street: (j['street'] ?? j['address_line_1'])?.toString() ?? '',
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    pincode: j['pincode']?.toString() ?? '',
    country: j['country']?.toString(),
    isDefault: j['is_default'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'street': street,
    'city': city,
    'state': state,
    'pincode': pincode,
    if (country != null && country!.isNotEmpty) 'country': country,
    'is_default': isDefault,
  };
}
