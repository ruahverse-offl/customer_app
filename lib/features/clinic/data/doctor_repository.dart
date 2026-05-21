import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'doctor_models.dart';

class DoctorRepository {
  final Dio _dio;
  const DoctorRepository(this._dio);

  Future<List<Doctor>> getDoctors() async {
    final res = await _dio.get('/doctors', queryParameters: {'limit': 100});
    final raw = res.data;
    final items = raw is Map ? (raw['items'] ?? []) : raw;
    return (items as List)
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .where((d) => d.isActive)
        .toList();
  }

  Future<Doctor> getDoctorById(String id) async {
    final res = await _dio.get('/doctors/$id');
    return Doctor.fromJson(res.data as Map<String, dynamic>);
  }
}

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});
