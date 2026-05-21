import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'polyclinic_models.dart';

class PolyclinicRepository {
  final Dio _dio;
  const PolyclinicRepository(this._dio);

  Future<List<PolyclinicTest>> getTests() async {
    final res = await _dio.get('/polyclinic-tests', queryParameters: {'limit': 100});
    final raw = res.data;
    final items = raw is Map ? (raw['items'] ?? []) : raw;
    return (items as List)
        .map((e) => PolyclinicTest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final polyclinicRepositoryProvider = Provider<PolyclinicRepository>((ref) {
  return PolyclinicRepository(ref.watch(dioProvider));
});
