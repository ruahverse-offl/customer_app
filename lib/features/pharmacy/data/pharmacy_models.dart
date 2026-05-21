import '../../../core/config/app_config.dart';

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
  final String? manufacturer;
  final String? packDescription;
  final double mrp;
  final int stockQuantity;
  final bool isActive;
  final bool isAvailable;

  const BrandOffering({
    required this.id,
    required this.brandName,
    this.manufacturer,
    this.packDescription,
    required this.mrp,
    required this.stockQuantity,
    required this.isActive,
    required this.isAvailable,
  });

  String get packLabel => packDescription ?? brandName;

  bool get isPurchasable => isActive && isAvailable && stockQuantity > 0;

  factory BrandOffering.fromJson(Map<String, dynamic> j) => BrandOffering(
    id: j['id'].toString(),
    brandName: j['brand_name']?.toString() ?? '',
    manufacturer: j['manufacturer']?.toString(),
    packDescription: j['description']?.toString(),
    mrp: double.tryParse(j['mrp']?.toString() ?? '0') ?? 0,
    stockQuantity: (j['stock_quantity'] as num?)?.toInt() ?? 0,
    isActive: j['is_active'] as bool? ?? true,
    isAvailable: j['is_available'] as bool? ?? true,
  );
}

class Medicine {
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final bool requiresPrescription;
  final String? imagePath;
  final List<BrandOffering> offerings;

  const Medicine({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.requiresPrescription,
    this.imagePath,
    required this.offerings,
  });

  String? get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return null;
    final p = imagePath!.trim();
    if (p.startsWith('http')) {
      // Legacy absolute URL that may be missing /storage/ prefix
      if (RegExp(r'^https?://').hasMatch(p) &&
          RegExp(r'/(medicine|prescription|others)/').hasMatch(p) &&
          !p.contains('/storage/')) {
        final uri = Uri.tryParse(p);
        if (uri != null) return uri.replace(path: '/storage${uri.path}').toString();
      }
      return p;
    }
    // GCS object key (medicines/, prescriptions/, others/) → use signed redirect endpoint
    if (p.startsWith('medicines/') || p.startsWith('prescriptions/') || p.startsWith('others/')) {
      return '${AppConfig.baseUrl}/storage/signed?path=${Uri.encodeComponent(p)}';
    }
    // Local storage path → served from /storage/ at API origin root
    final rel = p.startsWith('/') ? p : '/storage/$p';
    return '${AppConfig.apiOrigin}$rel';
  }

  List<BrandOffering> get purchasableOfferings =>
      offerings.where((o) => o.isPurchasable).toList();

  double? get lowestPrice {
    final available = purchasableOfferings;
    if (available.isEmpty) return null;
    return available.map((o) => o.mrp).reduce((a, b) => a < b ? a : b);
  }

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    id: j['id'].toString(),
    name: j['name']?.toString() ?? '',
    categoryId: j['medicine_category_id']?.toString(),
    categoryName: j['medicine_category_name']?.toString(),
    requiresPrescription: j['is_prescription_required'] as bool? ?? false,
    imagePath: j['image_path']?.toString(),
    offerings: (j['brands'] as List? ?? [])
        .map((e) => BrandOffering.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
