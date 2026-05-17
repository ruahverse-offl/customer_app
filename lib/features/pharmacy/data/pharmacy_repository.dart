import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'pharmacy_models.dart';

class PharmacyRepository {
  final Dio _dio;
  const PharmacyRepository(this._dio);

  Future<List<MedicineCategory>> getCategories() async {
    final res = await _dio.get('/medicine-categories/');
    final items = (res.data['items'] ?? res.data) as List;
    return items.map((e) => MedicineCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({List<Medicine> items, int total})> getMedicines({
    String? search,
    List<String>? categoryIds,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryIds != null && categoryIds.isNotEmpty) params['category_id'] = categoryIds.join(',');

    final res = await _dio.get('/medicines/', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).map((e) => Medicine.fromJson(e as Map<String, dynamic>)).toList();
    final total = int.tryParse(data['pagination']?['total']?.toString() ?? '0') ?? 0;
    return (items: items, total: total);
  }
}

final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) {
  return PharmacyRepository(ref.watch(dioProvider));
});
