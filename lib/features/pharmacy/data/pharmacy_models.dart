class MedicineCategory {
  final String id;
  final String name;
  const MedicineCategory({required this.id, required this.name});
  factory MedicineCategory.fromJson(Map<String, dynamic> j) =>
      MedicineCategory(id: j['id'].toString(), name: j['name'].toString());
}

class BrandOffering {
  final String id;
  final String brandName;
  final String packSize;
  final String packUnit;
  final double price;
  final double mrp;
  final int stockQuantity;

  const BrandOffering({
    required this.id,
    required this.brandName,
    required this.packSize,
    required this.packUnit,
    required this.price,
    required this.mrp,
    required this.stockQuantity,
  });

  String get packLabel => '$packSize $packUnit';

  factory BrandOffering.fromJson(Map<String, dynamic> j) => BrandOffering(
    id: j['id'].toString(),
    brandName: j['brand_name']?.toString() ?? j['brand']?.toString() ?? '',
    packSize: j['pack_size']?.toString() ?? '',
    packUnit: j['pack_unit']?.toString() ?? '',
    price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
    mrp: double.tryParse(j['mrp']?.toString() ?? '0') ?? 0,
    stockQuantity: int.tryParse(j['stock_quantity']?.toString() ?? '0') ?? 0,
  );
}

class Medicine {
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final bool requiresPrescription;
  final String? imageUrl;
  final List<BrandOffering> offerings;

  const Medicine({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.requiresPrescription,
    this.imageUrl,
    required this.offerings,
  });

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    id: j['id'].toString(),
    name: j['name']?.toString() ?? '',
    categoryId: j['category_id']?.toString(),
    categoryName: j['category_name']?.toString(),
    requiresPrescription: j['requires_prescription'] as bool? ?? false,
    imageUrl: j['image_url']?.toString(),
    offerings: (j['brand_offerings'] as List? ?? [])
        .map((e) => BrandOffering.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
