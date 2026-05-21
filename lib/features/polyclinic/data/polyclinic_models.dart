class PolyclinicTest {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? duration;
  final bool fastingRequired;
  final String? iconName;

  const PolyclinicTest({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.duration,
    required this.fastingRequired,
    this.iconName,
  });

  factory PolyclinicTest.fromJson(Map<String, dynamic> j) => PolyclinicTest(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
        duration: j['duration']?.toString(),
        fastingRequired: j['fasting_required'] as bool? ?? false,
        iconName: j['icon_name']?.toString(),
      );
}
